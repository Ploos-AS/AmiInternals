#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m3-batch2}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(Vectors Patches Alerts)
for tool in "${TOOLS[@]}"; do
  test -s "build/fs-uae/native/$tool" || { echo "ERROR: missing native $tool" >&2; exit 1; }
done

iso="$(bash ci/fs-uae/fetch-aros-system.sh "$SYSTEM_DIR" | tail -n 1)"
root_extract="$OUT_DIR/system-root"
rm -rf "$root_extract"
mkdir -p "$root_extract"
7z x -y -o"$root_extract" "$iso" >/dev/null

# Use the ISO root system, never the nested Emergency-Boot environment.
startup="$(find "$root_extract" -maxdepth 2 -type f -ipath '*/s/startup-sequence' -print -quit)"
[[ -n "$startup" ]] || { echo 'ERROR: missing Startup-Sequence' >&2; exit 1; }
aros_root="$(dirname "$(dirname "$startup")")"
tool_dir="$aros_root/AmiInternalsTest"
mkdir -p "$tool_dir"
for tool in "${TOOLS[@]}"; do cp "build/fs-uae/native/$tool" "$tool_dir/$tool"; done

cp "$startup" "$startup.amiinternals-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "M3_BATCH2_STARTED=1" >SYS:m3b2-started.txt
SYS:AmiInternalsTest/Vectors >SYS:m3b2-vectors.txt
SYS:C/Echo $RC >SYS:m3b2-vectors-rc.txt
SYS:C/Echo "AFTER_VECTORS=1" >SYS:m3b2-after-vectors.txt
SYS:AmiInternalsTest/Patches >SYS:m3b2-patches.txt
SYS:C/Echo $RC >SYS:m3b2-patches-rc.txt
SYS:C/Echo "AFTER_PATCHES=1" >SYS:m3b2-after-patches.txt
SYS:AmiInternalsTest/Alerts >SYS:m3b2-alerts.txt
SYS:C/Echo $RC >SYS:m3b2-alerts-rc.txt
SYS:C/Echo "AFTER_ALERTS=1" >SYS:m3b2-after-alerts.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true
set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

check() {
  local key="$1" title="$2" marker="$3"
  local out="$aros_root/m3b2-$key.txt" after="$aros_root/m3b2-after-$key.txt" rcfile="$aros_root/m3b2-$key-rc.txt" rc
  [[ -f "$out" && -f "$after" && -f "$rcfile" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 0 ]] && grep -q "$title 0.1" "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q "$marker" "$out"; then echo PASS; else echo FAIL; fi
}

vectors_status=$(check vectors Vectors 'Vector Address Name')
patches_status=$(check patches Patches 'Hook Address')
alerts_status=$(check alerts Alerts 'LastAlert')

status=FAIL
if [[ "$vectors_status" == PASS && "$patches_status" == PASS && "$alerts_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M3_BATCH2_AROS_GUEST'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "VECTORS_STATUS=$vectors_status"
  echo "PATCHES_STATUS=$patches_status"
  echo "ALERTS_STATUS=$alerts_status"
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_KICKSTART_1_2_RUNTIME_STILL_REQUIRED'
  for key in vectors patches alerts; do
    [[ -f "$aros_root/m3b2-$key.txt" ]] && tr -d '\r' < "$aros_root/m3b2-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
