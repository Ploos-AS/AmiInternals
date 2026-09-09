#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-guest}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(Info Mem Tasks Libs Ports Devices Resources)
for tool in "${TOOLS[@]}"; do
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
for tool in "${TOOLS[@]}"; do
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
SYS:C/Echo "AMIINTERNALS_BEFORE_PORTS=1" >SYS:amiinternals-before-ports.txt
SYS:Ports >SYS:amiinternals-ports.txt
SYS:C/Echo $RC >SYS:amiinternals-ports-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_PORTS=1" >SYS:amiinternals-after-ports.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_DEVICES=1" >SYS:amiinternals-before-devices.txt
SYS:Devices >SYS:amiinternals-devices.txt
SYS:C/Echo $RC >SYS:amiinternals-devices-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_DEVICES=1" >SYS:amiinternals-after-devices.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_RESOURCES=1" >SYS:amiinternals-before-resources.txt
SYS:Resources >SYS:amiinternals-resources.txt
SYS:C/Echo $RC >SYS:amiinternals-resources-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_RESOURCES=1" >SYS:amiinternals-after-resources.txt
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

check_tool() {
  local key="$1"
  local title="$2"
  local marker="$3"
  local out="$aros_root/amiinternals-$key.txt"
  local after="$aros_root/amiinternals-after-$key.txt"

  if [[ -f "$after" && -f "$out" ]] && grep -q "$title 0.1" "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q "$marker" "$out"; then
    echo PASS
  else
    echo FAIL
  fi
}

info_status=$(check_tool info Info 'Exec')
mem_status=$(check_tool mem Mem 'Largest')
tasks_status=$(check_tool tasks Tasks 'State Pri Name')
libs_status=$(check_tool libs Libs 'Version Name')
ports_status=$(check_tool ports Ports 'Sig Name')
devices_status=$(check_tool devices Devices 'Version Name')
resources_status=$(check_tool resources Resources 'Name')

status=FAIL
observation=guest_tool_failure
if [[ "$info_status" == PASS && "$mem_status" == PASS && "$tasks_status" == PASS && "$libs_status" == PASS && "$ports_status" == PASS && "$devices_status" == PASS && "$resources_status" == PASS ]]; then
  status=PASS
  observation=guest_executed_full_m0_7_m0_9_batch
else
  for key in info mem tasks libs ports devices resources; do
    if [[ ! -f "$aros_root/amiinternals-after-$key.txt" && -f "$aros_root/amiinternals-before-$key.txt" ]]; then
      observation="${key}_did_not_return"
      break
    fi
  done
fi

{
  echo "STATUS=$status"
  echo "GATE=M0_7_M0_9_AROS_GUEST_BATCH"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "INFO_STATUS=$info_status"
  echo "MEM_STATUS=$mem_status"
  echo "TASKS_STATUS=$tasks_status"
  echo "LIBS_STATUS=$libs_status"
  echo "PORTS_STATUS=$ports_status"
  echo "DEVICES_STATUS=$devices_status"
  echo "RESOURCES_STATUS=$resources_status"
  echo "OBSERVATION=$observation"
  for key in info mem tasks libs ports devices resources; do
    rcfile="$aros_root/amiinternals-$key-rc.txt"
    outfile="$aros_root/amiinternals-$key.txt"
    upper=$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')
    if [[ -f "$rcfile" ]]; then tr -d '\r' < "$rcfile" | sed "s/^/${upper}_GUEST_RC=/"; fi
    if [[ -f "$outfile" ]]; then tr -d '\r' < "$outfile" | sed "s/^/GUEST_${upper}=/"; fi
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
