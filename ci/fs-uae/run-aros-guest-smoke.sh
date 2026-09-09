#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-guest}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(Info Mem Tasks Libs Ports Devices Resources Residents Assigns Mounts DF DU Find Which Tree Env)
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
tool_dir="$aros_root/AmiInternalsTest"
rm -rf "$tool_dir"
mkdir -p "$tool_dir"
for tool in "${TOOLS[@]}"; do
  cp "build/fs-uae/native/$tool" "$tool_dir/$tool"
done
cp "$startup" "$startup.amiinternals-original"

cat > "$startup" <<'EOF'
SYS:C/Echo "AMIINTERNALS_GUEST_STARTED=1" >SYS:amiinternals-started.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_INFO=1" >SYS:amiinternals-before-info.txt
SYS:AmiInternalsTest/Info >SYS:amiinternals-info.txt
SYS:C/Echo $RC >SYS:amiinternals-info-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_INFO=1" >SYS:amiinternals-after-info.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_MEM=1" >SYS:amiinternals-before-mem.txt
SYS:AmiInternalsTest/Mem >SYS:amiinternals-mem.txt
SYS:C/Echo $RC >SYS:amiinternals-mem-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_MEM=1" >SYS:amiinternals-after-mem.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_TASKS=1" >SYS:amiinternals-before-tasks.txt
SYS:AmiInternalsTest/Tasks >SYS:amiinternals-tasks.txt
SYS:C/Echo $RC >SYS:amiinternals-tasks-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_TASKS=1" >SYS:amiinternals-after-tasks.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_LIBS=1" >SYS:amiinternals-before-libs.txt
SYS:AmiInternalsTest/Libs >SYS:amiinternals-libs.txt
SYS:C/Echo $RC >SYS:amiinternals-libs-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_LIBS=1" >SYS:amiinternals-after-libs.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_PORTS=1" >SYS:amiinternals-before-ports.txt
SYS:AmiInternalsTest/Ports >SYS:amiinternals-ports.txt
SYS:C/Echo $RC >SYS:amiinternals-ports-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_PORTS=1" >SYS:amiinternals-after-ports.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_DEVICES=1" >SYS:amiinternals-before-devices.txt
SYS:AmiInternalsTest/Devices >SYS:amiinternals-devices.txt
SYS:C/Echo $RC >SYS:amiinternals-devices-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_DEVICES=1" >SYS:amiinternals-after-devices.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_RESOURCES=1" >SYS:amiinternals-before-resources.txt
SYS:AmiInternalsTest/Resources >SYS:amiinternals-resources.txt
SYS:C/Echo $RC >SYS:amiinternals-resources-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_RESOURCES=1" >SYS:amiinternals-after-resources.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_RESIDENTS=1" >SYS:amiinternals-before-residents.txt
SYS:AmiInternalsTest/Residents >SYS:amiinternals-residents.txt
SYS:C/Echo $RC >SYS:amiinternals-residents-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_RESIDENTS=1" >SYS:amiinternals-after-residents.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_ASSIGNS=1" >SYS:amiinternals-before-assigns.txt
SYS:AmiInternalsTest/Assigns >SYS:amiinternals-assigns.txt
SYS:C/Echo $RC >SYS:amiinternals-assigns-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_ASSIGNS=1" >SYS:amiinternals-after-assigns.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_MOUNTS=1" >SYS:amiinternals-before-mounts.txt
SYS:AmiInternalsTest/Mounts >SYS:amiinternals-mounts.txt
SYS:C/Echo $RC >SYS:amiinternals-mounts-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_MOUNTS=1" >SYS:amiinternals-after-mounts.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_DF=1" >SYS:amiinternals-before-df.txt
SYS:AmiInternalsTest/DF >SYS:amiinternals-df.txt
SYS:C/Echo $RC >SYS:amiinternals-df-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_DF=1" >SYS:amiinternals-after-df.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_DU=1" >SYS:amiinternals-before-du.txt
SYS:AmiInternalsTest/DU SYS:AmiInternalsTest >SYS:amiinternals-du.txt
SYS:C/Echo $RC >SYS:amiinternals-du-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_DU=1" >SYS:amiinternals-after-du.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_FIND=1" >SYS:amiinternals-before-find.txt
SYS:AmiInternalsTest/Find Info SYS:AmiInternalsTest >SYS:amiinternals-find.txt
SYS:C/Echo $RC >SYS:amiinternals-find-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_FIND=1" >SYS:amiinternals-after-find.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_WHICH=1" >SYS:amiinternals-before-which.txt
SYS:AmiInternalsTest/Which SYS:AmiInternalsTest/Info >SYS:amiinternals-which.txt
SYS:C/Echo $RC >SYS:amiinternals-which-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_WHICH=1" >SYS:amiinternals-after-which.txt
SYS:C/MakeDir SYS:AmiInternalsTree
SYS:C/MakeDir SYS:AmiInternalsTree/Sub
SYS:C/Echo "tree-smoke" >SYS:AmiInternalsTree/Sub/Leaf.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_TREE=1" >SYS:amiinternals-before-tree.txt
SYS:AmiInternalsTest/Tree SYS:AmiInternalsTree >SYS:amiinternals-tree.txt
SYS:C/Echo $RC >SYS:amiinternals-tree-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_TREE=1" >SYS:amiinternals-after-tree.txt
SYS:C/Echo "ENV_FIXTURE_BEFORE_MAKEDIR=1" >SYS:amiinternals-env-stage0.txt
SYS:C/MakeDir RAM:Env
SYS:C/Echo "ENV_FIXTURE_AFTER_MAKEDIR=1" >SYS:amiinternals-env-stage1.txt
SYS:C/Assign ENV: RAM:Env
SYS:C/Echo "ENV_FIXTURE_AFTER_ASSIGN=1" >SYS:amiinternals-env-stage2.txt
SYS:C/Echo "AMIINTERNALS_ENV_VALUE" >ENV:AMIINTERNALS_TEST
SYS:C/Echo "ENV_FIXTURE_AFTER_WRITE=1" >SYS:amiinternals-env-stage3.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_ENV=1" >SYS:amiinternals-before-env.txt
SYS:AmiInternalsTest/Env AMIINTERNALS_TEST >SYS:amiinternals-env.txt
SYS:C/Echo $RC >SYS:amiinternals-env-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_ENV=1" >SYS:amiinternals-after-env.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

rm -f "$aros_root"/amiinternals-*.txt
rm -rf "$aros_root/AmiInternalsTree"

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
residents_status=$(check_tool residents Residents 'Ver Type Pri Name')
assigns_status=$(check_tool assigns Assigns 'Type Name')
mounts_status=$(check_tool mounts Mounts 'State Name')
df_status=$(check_tool df DF 'BlockSize Total Used Free Name')
du_status=$(check_tool du DU 'Bytes Files Dirs Errors Path')
find_status=$(check_tool find Find 'Matches:')
which_status=$(check_tool which Which 'SYS:AmiInternalsTest/Info')
tree_status=$(check_tool tree Tree 'Leaf.txt')
env_status=$(check_tool env Env 'AMIINTERNALS_TEST=AMIINTERNALS_ENV_VALUE')

status=FAIL
observation=guest_tool_failure
if [[ "$info_status" == PASS && "$mem_status" == PASS && "$tasks_status" == PASS && "$libs_status" == PASS && "$ports_status" == PASS && "$devices_status" == PASS && "$resources_status" == PASS && "$residents_status" == PASS && "$assigns_status" == PASS && "$mounts_status" == PASS && "$df_status" == PASS && "$du_status" == PASS && "$find_status" == PASS && "$which_status" == PASS && "$tree_status" == PASS && "$env_status" == PASS ]]; then
  status=PASS
  observation=guest_executed_full_m2_4_m2_6_batch
else
  for key in info mem tasks libs ports devices resources residents assigns mounts df du find which tree env; do
    if [[ ! -f "$aros_root/amiinternals-after-$key.txt" && -f "$aros_root/amiinternals-before-$key.txt" ]]; then
      observation="${key}_did_not_return"
      break
    fi
  done
fi

{
  echo "STATUS=$status"
  echo "GATE=M2_4_M2_6_AROS_GUEST_BATCH"
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
  echo "RESIDENTS_STATUS=$residents_status"
  echo "ASSIGNS_STATUS=$assigns_status"
  echo "MOUNTS_STATUS=$mounts_status"
  echo "DF_STATUS=$df_status"
  echo "DU_STATUS=$du_status"
  echo "FIND_STATUS=$find_status"
  echo "WHICH_STATUS=$which_status"
  echo "TREE_STATUS=$tree_status"
  echo "ENV_STATUS=$env_status"
  echo "OBSERVATION=$observation"
  for stage in 0 1 2 3; do
    stagefile="$aros_root/amiinternals-env-stage${stage}.txt"
    if [[ -f "$stagefile" ]]; then
      tr -d '\r' < "$stagefile" | sed "s/^/ENV_STAGE${stage}=/"
    else
      echo "ENV_STAGE${stage}=MISSING"
    fi
  done
  for key in info mem tasks libs ports devices resources residents assigns mounts df du find which tree env; do
    rcfile="$aros_root/amiinternals-$key-rc.txt"
    outfile="$aros_root/amiinternals-$key.txt"
    upper=$(printf '%s' "$key" | tr '[:lower:]' '[:upper:]')
    if [[ -f "$rcfile" ]]; then tr -d '\r' < "$rcfile" | sed "s/^/${upper}_GUEST_RC=/"; fi
    if [[ -f "$outfile" ]]; then tr -d '\r' < "$outfile" | sed "s/^/GUEST_${upper}=/"; fi
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
