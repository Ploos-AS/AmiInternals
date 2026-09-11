#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m4-batch3}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(WatchPort WatchMem)
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
SYS:C/Echo "M4_BATCH3_STARTED=1" >SYS:m4b3-started.txt
SYS:AmiInternalsTest/WatchPort __AMIINTERNALS_MISSING_PORT__ 1 >SYS:m4b3-watchport.txt
SYS:C/Echo $RC >SYS:m4b3-watchport-rc.txt
SYS:C/Echo "AFTER_WATCHPORT=1" >SYS:m4b3-after-watchport.txt
SYS:AmiInternalsTest/WatchMem 1 >SYS:m4b3-watchmem.txt
SYS:C/Echo $RC >SYS:m4b3-watchmem-rc.txt
SYS:C/Echo "AFTER_WATCHMEM=1" >SYS:m4b3-after-watchmem.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true
set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

check_watchport() {
  local out="$aros_root/m4b3-watchport.txt" rcfile="$aros_root/m4b3-watchport-rc.txt" after="$aros_root/m4b3-after-watchport.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 5 ]] && grep -q 'WatchPort 0.1' "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q 'ABSENT' "$out" && grep -q 'Seen 0/1' "$out"; then echo PASS; else echo FAIL; fi
}

check_watchmem() {
  local out="$aros_root/m4b3-watchmem.txt" rcfile="$aros_root/m4b3-watchmem-rc.txt" after="$aros_root/m4b3-after-watchmem.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 0 ]] && grep -q 'WatchMem 0.1' "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q 'Sample ChipFree FastFree TotalFree' "$out" && grep -q 'FirstTotal ' "$out" && grep -q 'LastTotal ' "$out"; then echo PASS; else echo FAIL; fi
}

watchport_status=$(check_watchport)
watchmem_status=$(check_watchmem)
status=FAIL
if [[ "$watchport_status" == PASS && "$watchmem_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M4_BATCH3_AROS_GUEST_M4_COMPLETE'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "WATCHPORT_STATUS=$watchport_status"
  echo "WATCHMEM_STATUS=$watchmem_status"
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_KICKSTART_1_2_RUNTIME_STILL_REQUIRED'
  for key in watchport watchmem; do
    [[ -f "$aros_root/m4b3-$key.txt" ]] && tr -d '\r' < "$aros_root/m4b3-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
