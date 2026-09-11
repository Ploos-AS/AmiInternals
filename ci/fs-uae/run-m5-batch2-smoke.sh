#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m5-batch2}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(TrackInfo FloppyTest DiskCheck)
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
SYS:C/Echo "M5_BATCH2_STARTED=1" >SYS:m5b2-started.txt
SYS:AmiInternalsTest/TrackInfo SYS: >SYS:m5b2-trackinfo.txt
SYS:C/Echo $RC >SYS:m5b2-trackinfo-rc.txt
SYS:C/Echo "AFTER_TRACKINFO=1" >SYS:m5b2-after-trackinfo.txt
SYS:AmiInternalsTest/FloppyTest SYS: >SYS:m5b2-floppytest.txt
SYS:C/Echo $RC >SYS:m5b2-floppytest-rc.txt
SYS:C/Echo "AFTER_FLOPPYTEST=1" >SYS:m5b2-after-floppytest.txt
SYS:AmiInternalsTest/DiskCheck SYS: >SYS:m5b2-diskcheck.txt
SYS:C/Echo $RC >SYS:m5b2-diskcheck-rc.txt
SYS:C/Echo "AFTER_DISKCHECK=1" >SYS:m5b2-after-diskcheck.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true
set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

check_rc0() {
  local key="$1" title="$2" marker="$3" marker2="${4:-}"
  local out="$aros_root/m5b2-$key.txt" rcfile="$aros_root/m5b2-$key-rc.txt" after="$aros_root/m5b2-after-$key.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 0 ]] \
    && grep -q "$title 0.1" "$out" \
    && grep -q 'AmiInternals - Ploos AS' "$out" \
    && grep -q "$marker" "$out" \
    && { [[ -z "$marker2" ]] || grep -q "$marker2" "$out"; }; then
    echo PASS
  else
    echo FAIL
  fi
}

trackinfo_status=$(check_rc0 trackinfo TrackInfo 'Geometry')
floppytest_status=$(check_rc0 floppytest FloppyTest 'DOSReadOnlyProbe PASS' 'SectorReadTest NOT PERFORMED')
diskcheck_status=$(check_rc0 diskcheck DiskCheck 'Status BASIC_CHECK_PASS')
status=FAIL
if [[ "$trackinfo_status" == PASS && "$floppytest_status" == PASS && "$diskcheck_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M5_BATCH2_AROS_GUEST'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "TRACKINFO_STATUS=$trackinfo_status"
  echo "FLOPPYTEST_STATUS=$floppytest_status"
  echo "DISKCHECK_STATUS=$diskcheck_status"
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_KICKSTART_1_2_RUNTIME_STILL_REQUIRED'
  for key in trackinfo floppytest diskcheck; do
    [[ -f "$aros_root/m5b2-$key.txt" ]] && tr -d '\r' < "$aros_root/m5b2-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
