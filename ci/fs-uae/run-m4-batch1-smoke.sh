#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m4-batch1}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(Doctor Snapshot SnapDiff)
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
SYS:C/Echo "M4_BATCH1_STARTED=1" >SYS:m4b1-started.txt
SYS:AmiInternalsTest/Doctor >SYS:m4b1-doctor.txt
SYS:C/Echo $RC >SYS:m4b1-doctor-rc.txt
SYS:AmiInternalsTest/Snapshot >SYS:m4b1-snapshot.txt
SYS:C/Echo $RC >SYS:m4b1-snapshot-rc.txt
SYS:C/Copy SYS:m4b1-snapshot.txt SYS:m4b1-snapshot-copy.txt QUIET
SYS:AmiInternalsTest/SnapDiff SYS:m4b1-snapshot.txt SYS:m4b1-snapshot-copy.txt >SYS:m4b1-snapdiff.txt
SYS:C/Echo $RC >SYS:m4b1-snapdiff-rc.txt
SYS:C/Echo "M4_BATCH1_DONE=1" >SYS:m4b1-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true
set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

read_rc() { tr -d '\r\n ' < "$1"; }
doctor_status=FAIL
snapshot_status=FAIL
snapdiff_status=FAIL

if [[ -f "$aros_root/m4b1-doctor.txt" && -f "$aros_root/m4b1-doctor-rc.txt" ]]; then
  rc="$(read_rc "$aros_root/m4b1-doctor-rc.txt")"
  if [[ ( "$rc" == 0 || "$rc" == 5 ) ]] && grep -q 'Doctor 0.1' "$aros_root/m4b1-doctor.txt" && grep -q 'Result:' "$aros_root/m4b1-doctor.txt"; then doctor_status=PASS; fi
fi

if [[ -f "$aros_root/m4b1-snapshot.txt" && -f "$aros_root/m4b1-snapshot-rc.txt" ]]; then
  rc="$(read_rc "$aros_root/m4b1-snapshot-rc.txt")"
  if [[ "$rc" == 0 ]] && grep -q 'Snapshot 0.1' "$aros_root/m4b1-snapshot.txt" && grep -q '^FORMAT=1' "$aros_root/m4b1-snapshot.txt" && grep -q '^EXEC_VERSION=' "$aros_root/m4b1-snapshot.txt"; then snapshot_status=PASS; fi
fi

if [[ -f "$aros_root/m4b1-snapdiff.txt" && -f "$aros_root/m4b1-snapdiff-rc.txt" ]]; then
  rc="$(read_rc "$aros_root/m4b1-snapdiff-rc.txt")"
  if [[ "$rc" == 0 ]] && grep -q 'SnapDiff 0.1' "$aros_root/m4b1-snapdiff.txt" && grep -q '^Result=IDENTICAL' "$aros_root/m4b1-snapdiff.txt"; then snapdiff_status=PASS; fi
fi

status=FAIL
if [[ "$doctor_status" == PASS && "$snapshot_status" == PASS && "$snapdiff_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M4_BATCH1_AROS_GUEST'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "DOCTOR_STATUS=$doctor_status"
  echo "SNAPSHOT_STATUS=$snapshot_status"
  echo "SNAPDIFF_STATUS=$snapdiff_status"
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_KICKSTART_1_2_RUNTIME_STILL_REQUIRED'
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
