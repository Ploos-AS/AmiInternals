#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m5-batch3}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(BootSave BootRestore)
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
SYS:C/Echo "M5_BATCH3_STARTED=1" >SYS:m5b3-started.txt
SYS:AmiInternalsTest/BootSave >SYS:m5b3-bootsave.txt
SYS:C/Echo $RC >SYS:m5b3-bootsave-rc.txt
SYS:C/Echo "AFTER_BOOTSAVE=1" >SYS:m5b3-after-bootsave.txt
SYS:AmiInternalsTest/BootRestore DF0: SYS:missing.boot NO >SYS:m5b3-bootrestore.txt
SYS:C/Echo $RC >SYS:m5b3-bootrestore-rc.txt
SYS:C/Echo "AFTER_BOOTRESTORE=1" >SYS:m5b3-after-bootrestore.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true
set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

check_usage() {
  local key="$1" title="$2" marker="$3"
  local out="$aros_root/m5b3-$key.txt" rcfile="$aros_root/m5b3-$key-rc.txt" after="$aros_root/m5b3-after-$key.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 10 ]] && grep -q "$title 0.1" "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q "$marker" "$out"; then echo PASS; else echo FAIL; fi
}

bootsave_status=$(check_usage bootsave BootSave 'Usage: BootSave')
bootrestore_status=$(check_usage bootrestore BootRestore 'Final YES is mandatory')
status=FAIL
if [[ "$bootsave_status" == PASS && "$bootrestore_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M5_BATCH3_AROS_GUEST'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "BOOTSAVE_STATUS=$bootsave_status"
  echo "BOOTRESTORE_STATUS=$bootrestore_status"
  echo 'WRITE_PATH_TESTED=NO'
  echo 'QUALIFICATION=AROS_SAFETY_SMOKE_ONLY_CLASSIC_FLOPPY_RUNTIME_STILL_REQUIRED'
  for key in bootsave bootrestore; do
    [[ -f "$aros_root/m5b3-$key.txt" ]] && tr -d '\r' < "$aros_root/m5b3-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
