#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-guest}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

for tool in Info Mem; do
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
cp build/fs-uae/native/Info "$aros_root/Info"
cp build/fs-uae/native/Mem "$aros_root/Mem"
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
info_rc="$aros_root/amiinternals-info-rc.txt"
info_after="$aros_root/amiinternals-after-info.txt"
mem_out="$aros_root/amiinternals-mem.txt"
mem_rc="$aros_root/amiinternals-mem-rc.txt"
mem_after="$aros_root/amiinternals-after-mem.txt"

info_status=FAIL
mem_status=FAIL

if [[ -f "$info_after" && -f "$info_out" ]] && grep -q 'Info 0.1' "$info_out" && grep -q 'AmiInternals - Ploos AS' "$info_out"; then
  info_status=PASS
fi

if [[ -f "$mem_after" && -f "$mem_out" ]] && grep -q 'Mem 0.1' "$mem_out" && grep -q 'AmiInternals - Ploos AS' "$mem_out" && grep -q 'Chip' "$mem_out" && grep -q 'Largest' "$mem_out"; then
  mem_status=PASS
fi

status=FAIL
observation=guest_tool_failure
if [[ "$info_status" == PASS && "$mem_status" == PASS ]]; then
  status=PASS
  observation=guest_executed_info_and_mem
elif [[ ! -f "$info_after" && -f "$aros_root/amiinternals-before-info.txt" ]]; then
  observation=info_did_not_return
elif [[ ! -f "$mem_after" && -f "$aros_root/amiinternals-before-mem.txt" ]]; then
  observation=mem_did_not_return
fi

{
  echo "STATUS=$status"
  echo "GATE=M0_4_AROS_GUEST_EXECUTION"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "INFO_STATUS=$info_status"
  echo "MEM_STATUS=$mem_status"
  echo "OBSERVATION=$observation"
  if [[ -f "$info_rc" ]]; then
    tr -d '\r' < "$info_rc" | sed 's/^/INFO_GUEST_RC=/'
  fi
  if [[ -f "$mem_rc" ]]; then
    tr -d '\r' < "$mem_rc" | sed 's/^/MEM_GUEST_RC=/'
  fi
  if [[ -f "$info_out" ]]; then
    tr -d '\r' < "$info_out" | sed 's/^/GUEST_INFO=/'
  fi
  if [[ -f "$mem_out" ]]; then
    tr -d '\r' < "$mem_out" | sed 's/^/GUEST_MEM=/'
  fi
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
