#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m4-batch2}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(Timer Bench WatchTask)
for tool in "${TOOLS[@]}"; do
  test -s "build/fs-uae/native/$tool" || { echo "ERROR: missing native $tool" >&2; exit 1; }
done

iso="$(bash ci/fs-uae/fetch-aros-system.sh "$SYSTEM_DIR" | tail -n 1)"
root_extract="$OUT_DIR/system-root"
rm -rf "$root_extract"
mkdir -p "$root_extract"
7z x -y -o"$root_extract" "$iso" >/dev/null

startup="$(find "$root_extract" -type f -ipath '*/s/startup-sequence' -print -quit)"
[[ -n "$startup" ]] || { echo 'ERROR: missing Startup-Sequence' >&2; exit 1; }
aros_root="$(dirname "$(dirname "$startup")")"
tool_dir="$aros_root/AmiInternalsTest"
mkdir -p "$tool_dir"
for tool in "${TOOLS[@]}"; do cp "build/fs-uae/native/$tool" "$tool_dir/$tool"; done

cp "$startup" "$startup.amiinternals-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "M4_BATCH2_STARTED=1" >SYS:m4b2-started.txt
SYS:AmiInternalsTest/Timer 0 >SYS:m4b2-timer.txt
SYS:C/Echo $RC >SYS:m4b2-timer-rc.txt
SYS:C/Echo "AFTER_TIMER=1" >SYS:m4b2-after-timer.txt
SYS:AmiInternalsTest/Bench 1 >SYS:m4b2-bench.txt
SYS:C/Echo $RC >SYS:m4b2-bench-rc.txt
SYS:C/Echo "AFTER_BENCH=1" >SYS:m4b2-after-bench.txt
SYS:AmiInternalsTest/WatchTask __AMIINTERNALS_MISSING_TASK__ 1 >SYS:m4b2-watchtask.txt
SYS:C/Echo $RC >SYS:m4b2-watchtask-rc.txt
SYS:C/Echo "AFTER_WATCHTASK=1" >SYS:m4b2-after-watchtask.txt
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
  local key="$1" title="$2" marker="$3"
  local out="$aros_root/m4b2-$key.txt" rcfile="$aros_root/m4b2-$key-rc.txt" after="$aros_root/m4b2-after-$key.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 0 ]] && grep -q "$title 0.1" "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q "$marker" "$out"; then echo PASS; else echo FAIL; fi
}

check_watchtask() {
  local out="$aros_root/m4b2-watchtask.txt" rcfile="$aros_root/m4b2-watchtask-rc.txt" after="$aros_root/m4b2-after-watchtask.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 5 ]] && grep -q 'WatchTask 0.1' "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q 'ABSENT' "$out" && grep -q 'Seen 0/1' "$out"; then echo PASS; else echo FAIL; fi
}

timer_status=$(check_rc0 timer Timer 'Elapsed ticks')
bench_status=$(check_rc0 bench Bench 'Checksum')
watchtask_status=$(check_watchtask)
status=FAIL
if [[ "$timer_status" == PASS && "$bench_status" == PASS && "$watchtask_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M4_BATCH2_AROS_GUEST'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "TIMER_STATUS=$timer_status"
  echo "BENCH_STATUS=$bench_status"
  echo "WATCHTASK_STATUS=$watchtask_status"
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_KICKSTART_1_2_RUNTIME_STILL_REQUIRED'
  for key in timer bench watchtask; do
    [[ -f "$aros_root/m4b2-$key.txt" ]] && tr -d '\r' < "$aros_root/m4b2-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
