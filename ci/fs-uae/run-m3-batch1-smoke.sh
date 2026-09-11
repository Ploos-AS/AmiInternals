#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m3-batch1}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(TaskInfo ExecInfo Interrupts)
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
SYS:C/Echo "M3_BATCH1_STARTED=1" >SYS:m3-started.txt
SYS:AmiInternalsTest/TaskInfo >SYS:m3-taskinfo.txt
SYS:C/Echo $RC >SYS:m3-taskinfo-rc.txt
SYS:C/Echo "AFTER_TASKINFO=1" >SYS:m3-after-taskinfo.txt
SYS:AmiInternalsTest/ExecInfo >SYS:m3-execinfo.txt
SYS:C/Echo $RC >SYS:m3-execinfo-rc.txt
SYS:C/Echo "AFTER_EXECINFO=1" >SYS:m3-after-execinfo.txt
SYS:AmiInternalsTest/Interrupts >SYS:m3-interrupts.txt
SYS:C/Echo $RC >SYS:m3-interrupts-rc.txt
SYS:C/Echo "AFTER_INTERRUPTS=1" >SYS:m3-after-interrupts.txt
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
  local out="$aros_root/m3-$key.txt" after="$aros_root/m3-after-$key.txt" rcfile="$aros_root/m3-$key-rc.txt" rc
  [[ -f "$out" && -f "$after" && -f "$rcfile" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 0 ]] && grep -q "$title 0.1" "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q "$marker" "$out"; then echo PASS; else echo FAIL; fi
}

taskinfo_status=$(check taskinfo TaskInfo 'Name')
execinfo_status=$(check execinfo ExecInfo 'Exec version')
interrupts_status=$(check interrupts Interrupts 'Int Code Data Name')

status=FAIL
if [[ "$taskinfo_status" == PASS && "$execinfo_status" == PASS && "$interrupts_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M3_BATCH1_AROS_GUEST'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "TASKINFO_STATUS=$taskinfo_status"
  echo "EXECINFO_STATUS=$execinfo_status"
  echo "INTERRUPTS_STATUS=$interrupts_status"
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_KICKSTART_1_2_RUNTIME_STILL_REQUIRED'
  for key in taskinfo execinfo interrupts; do
    [[ -f "$aros_root/m3-$key.txt" ]] && tr -d '\r' < "$aros_root/m3-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
