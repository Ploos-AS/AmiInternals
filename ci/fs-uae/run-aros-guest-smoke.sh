#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-guest}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

for tool in Info Mem Tasks Libs; do
  if [[ ! -f "build/fs-uae/native/$tool" ]]; then
    echo "ERROR: native $tool binary missing; run build-native.sh first" >&2
    exit 1
  fi
done

iso="$(bash ci/fs-uae/fetch-aros-system.sh "$SYSTEM_DIR" | tail -n 1)"
root_extract="$OUT_DIR/system-root"
rm -rf "$root_extract"
mkdir -p "$root_extract"
7z x -y -o"$root_extract" "$iso" >/dev/null

startup="$(find "$root_extract" -type f -ipath '*/s/startup-sequence' -print -quit)"
if [[ -z "$startup" ]]; then
  echo "ERROR: AROS system ISO does not contain S/Startup-Sequence" >&2
  exit 1
fi

aros_root="$(dirname "$(dirname "$startup")")"
for tool in Info Mem Tasks Libs; do
  cp "build/fs-uae/native/$tool" "$aros_root/$tool"
done
cp "$startup" "$startup.amiinternals-original"

cat > "$startup" <<'EOF'
SYS:C/Echo "AMIINTERNALS_GUEST_STARTED=1" >SYS:amiinternals-started.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_INFO=1" >SYS:amiinternals-before-info.txt
SYS:Info >SYS:amiinternals-info.txt
SYS:C/Echo $RC >SYS:amiinternals-info-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_INFO=1" >SYS:amiinternals-after-info.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_MEM=1" >SYS:amiinternals-before-mem.txt
SYS:Mem >SYS:amiinternals-mem.txt
SYS:C/Echo $RC >SYS:amiinternals-mem-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_MEM=1" >SYS:amiinternals-after-mem.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_TASKS=1" >SYS:amiinternals-before-tasks.txt
SYS:Tasks >SYS:amiinternals-tasks.txt
SYS:C/Echo $RC >SYS:amiinternals-tasks-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_TASKS=1" >SYS:amiinternals-after-tasks.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_LIBS=1" >SYS:amiinternals-before-libs.txt
SYS:Libs >SYS:amiinternals-libs.txt
SYS:C/Echo $RC >SYS:amiinternals-libs-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_LIBS=1" >SYS:amiinternals-after-libs.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

rm -f "$aros_root"/amiinternals-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

info_out="$aros_root/amiinternals-info.txt"
mem_out="$aros_root/amiinternals-mem.txt"
tasks_out="$aros_root/amiinternals-tasks.txt"
libs_out="$aros_root/amiinternals-libs.txt"
info_rc="$aros_root/amiinternals-info-rc.txt"
mem_rc="$aros_root/amiinternals-mem-rc.txt"
tasks_rc="$aros_root/amiinternals-tasks-rc.txt"
libs_rc="$aros_root/amiinternals-libs-rc.txt"

info_status=FAIL
mem_status=FAIL
tasks_status=FAIL
libs_status=FAIL

if [[ -f "$aros_root/amiinternals-after-info.txt" && -f "$info_out" ]] && grep -q 'Info 0.1' "$info_out" && grep -q 'AmiInternals - Ploos AS' "$info_out"; then
  info_status=PASS
fi

if [[ -f "$aros_root/amiinternals-after-mem.txt" && -f "$mem_out" ]] && grep -q 'Mem 0.1' "$mem_out" && grep -q 'AmiInternals - Ploos AS' "$mem_out" && grep -q 'Chip' "$mem_out" && grep -q 'Largest' "$mem_out"; then
  mem_status=PASS
fi

if [[ -f "$aros_root/amiinternals-after-tasks.txt" && -f "$tasks_out" ]] && grep -q 'Tasks 0.1' "$tasks_out" && grep -q 'AmiInternals - Ploos AS' "$tasks_out" && grep -q 'State Pri Name' "$tasks_out"; then
  tasks_status=PASS
fi

if [[ -f "$aros_root/amiinternals-after-libs.txt" && -f "$libs_out" ]] && grep -q 'Libs 0.1' "$libs_out" && grep -q 'AmiInternals - Ploos AS' "$libs_out" && grep -q 'Version Name' "$libs_out"; then
  libs_status=PASS
fi

status=FAIL
observation=guest_tool_failure
if [[ "$info_status" == PASS && "$mem_status" == PASS && "$tasks_status" == PASS && "$libs_status" == PASS ]]; then
  status=PASS
  observation=guest_executed_info_mem_tasks_and_libs
elif [[ ! -f "$aros_root/amiinternals-after-info.txt" && -f "$aros_root/amiinternals-before-info.txt" ]]; then
  observation=info_did_not_return
elif [[ ! -f "$aros_root/amiinternals-after-mem.txt" && -f "$aros_root/amiinternals-before-mem.txt" ]]; then
  observation=mem_did_not_return
elif [[ ! -f "$aros_root/amiinternals-after-tasks.txt" && -f "$aros_root/amiinternals-before-tasks.txt" ]]; then
  observation=tasks_did_not_return
elif [[ ! -f "$aros_root/amiinternals-after-libs.txt" && -f "$aros_root/amiinternals-before-libs.txt" ]]; then
  observation=libs_did_not_return
fi

{
  echo "STATUS=$status"
  echo "GATE=M0_6_AROS_GUEST_EXECUTION"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "INFO_STATUS=$info_status"
  echo "MEM_STATUS=$mem_status"
  echo "TASKS_STATUS=$tasks_status"
  echo "LIBS_STATUS=$libs_status"
  echo "OBSERVATION=$observation"
  if [[ -f "$info_rc" ]]; then tr -d '\r' < "$info_rc" | sed 's/^/INFO_GUEST_RC=/'; fi
  if [[ -f "$mem_rc" ]]; then tr -d '\r' < "$mem_rc" | sed 's/^/MEM_GUEST_RC=/'; fi
  if [[ -f "$tasks_rc" ]]; then tr -d '\r' < "$tasks_rc" | sed 's/^/TASKS_GUEST_RC=/'; fi
  if [[ -f "$libs_rc" ]]; then tr -d '\r' < "$libs_rc" | sed 's/^/LIBS_GUEST_RC=/'; fi
  if [[ -f "$info_out" ]]; then tr -d '\r' < "$info_out" | sed 's/^/GUEST_INFO=/'; fi
  if [[ -f "$mem_out" ]]; then tr -d '\r' < "$mem_out" | sed 's/^/GUEST_MEM=/'; fi
  if [[ -f "$tasks_out" ]]; then tr -d '\r' < "$tasks_out" | sed 's/^/GUEST_TASKS=/'; fi
  if [[ -f "$libs_out" ]]; then tr -d '\r' < "$libs_out" | sed 's/^/GUEST_LIBS=/'; fi
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
