#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m3-batch3}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(Handlers InputInfo)
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
SYS:C/Echo "M3_BATCH3_STARTED=1" >SYS:m3b3-started.txt
SYS:AmiInternalsTest/Handlers >SYS:m3b3-handlers.txt
SYS:C/Echo $RC >SYS:m3b3-handlers-rc.txt
SYS:C/Echo "AFTER_HANDLERS=1" >SYS:m3b3-after-handlers.txt
SYS:AmiInternalsTest/InputInfo >SYS:m3b3-inputinfo.txt
SYS:C/Echo $RC >SYS:m3b3-inputinfo-rc.txt
SYS:C/Echo "AFTER_INPUTINFO=1" >SYS:m3b3-after-inputinfo.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true
set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

check_handlers() {
  local out="$aros_root/m3b3-handlers.txt" rcfile="$aros_root/m3b3-handlers-rc.txt" after="$aros_root/m3b3-after-handlers.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 0 ]] && grep -q 'Handlers 0.1' "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q 'Task Name' "$out"; then echo PASS; else echo FAIL; fi
}

check_inputinfo() {
  local out="$aros_root/m3b3-inputinfo.txt" rcfile="$aros_root/m3b3-inputinfo-rc.txt" after="$aros_root/m3b3-after-inputinfo.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ ( "$rc" == 0 || "$rc" == 5 ) ]] && grep -q 'InputInfo 0.1' "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q 'Device' "$out"; then echo PASS; else echo FAIL; fi
}

handlers_status=$(check_handlers)
inputinfo_status=$(check_inputinfo)
status=FAIL
if [[ "$handlers_status" == PASS && "$inputinfo_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M3_BATCH3_AROS_GUEST_M3_COMPLETE'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "HANDLERS_STATUS=$handlers_status"
  echo "INPUTINFO_STATUS=$inputinfo_status"
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_KICKSTART_1_2_RUNTIME_STILL_REQUIRED'
  for key in handlers inputinfo; do
    [[ -f "$aros_root/m3b3-$key.txt" ]] && tr -d '\r' < "$aros_root/m3b3-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
