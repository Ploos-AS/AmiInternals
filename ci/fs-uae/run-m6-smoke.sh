#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m6}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(RexxPorts RexxSend RexxProbe)
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
SYS:C/FailAt 21
SYS:C/Echo "M6_STARTED=1" >SYS:m6-started.txt
SYS:AmiInternalsTest/RexxPorts >SYS:m6-rexxports.txt
SYS:C/Echo $RC >SYS:m6-rexxports-rc.txt
SYS:AmiInternalsTest/RexxProbe __AMIINTERNALS_MISSING_REXX_PORT__ >SYS:m6-rexxprobe.txt
SYS:C/Echo $RC >SYS:m6-rexxprobe-rc.txt
SYS:AmiInternalsTest/RexxSend __AMIINTERNALS_MISSING_REXX_PORT__ NOP >SYS:m6-rexxsend.txt
SYS:C/Echo $RC >SYS:m6-rexxsend-rc.txt
SYS:C/Echo "M6_FINISHED=1" >SYS:m6-finished.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true
set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

read_rc() {
  local file="$1"
  [[ -f "$file" ]] || { echo MISSING; return; }
  tr -d '\r\n ' < "$file"
}

rexxports_rc="$(read_rc "$aros_root/m6-rexxports-rc.txt")"
rexxprobe_rc="$(read_rc "$aros_root/m6-rexxprobe-rc.txt")"
rexxsend_rc="$(read_rc "$aros_root/m6-rexxsend-rc.txt")"

rexxports_status=FAIL
if [[ "$rexxports_rc" == 0 ]] && grep -q 'RexxPorts 0.1' "$aros_root/m6-rexxports.txt" && grep -q 'Exec MsgPorts are not type-tagged as ARexx' "$aros_root/m6-rexxports.txt"; then
  rexxports_status=PASS
fi

rexxprobe_status=FAIL
if [[ "$rexxprobe_rc" == 5 ]] && grep -q 'RexxProbe 0.1' "$aros_root/m6-rexxprobe.txt" && grep -q '__AMIINTERNALS_MISSING_REXX_PORT__ ABSENT' "$aros_root/m6-rexxprobe.txt"; then
  rexxprobe_status=PASS
fi

rexxsend_status=FAIL
if [[ "$rexxsend_rc" == 5 ]] && grep -q 'RexxSend 0.1' "$aros_root/m6-rexxsend.txt" && \
   grep -Eq 'ARexx unavailable: rexxsyslib.library not present|Target port not found' "$aros_root/m6-rexxsend.txt"; then
  rexxsend_status=PASS
fi

status=FAIL
if [[ "$rexxports_status" == PASS && "$rexxprobe_status" == PASS && "$rexxsend_status" == PASS && -f "$aros_root/m6-finished.txt" ]]; then
  status=PASS
fi

{
  echo "STATUS=$status"
  echo 'GATE=M6_AROS_GUEST'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "REXXPORTS_STATUS=$rexxports_status"
  echo "REXXPROBE_STATUS=$rexxprobe_status"
  echo "REXXSEND_STATUS=$rexxsend_status"
  echo "REXXPORTS_RC=$rexxports_rc"
  echo "REXXPROBE_RC=$rexxprobe_rc"
  echo "REXXSEND_RC=$rexxsend_rc"
  echo 'ARexx_ACTIVE_COMMAND_PATH_TESTED=NO'
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_CLASSIC_KS1_2_GRACEFUL_ABSENCE_AND_OS2X_AREXX_RUNTIME_STILL_REQUIRED'
  for key in rexxports rexxprobe rexxsend; do
    [[ -f "$aros_root/m6-$key.txt" ]] && tr -d '\r' < "$aros_root/m6-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
