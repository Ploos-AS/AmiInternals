#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/m5-batch1}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

TOOLS=(DiskInfo BootInfo ROMInfo)
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
SYS:C/Echo "M5_BATCH1_STARTED=1" >SYS:m5b1-started.txt
SYS:AmiInternalsTest/DiskInfo SYS: >SYS:m5b1-diskinfo.txt
SYS:C/Echo $RC >SYS:m5b1-diskinfo-rc.txt
SYS:C/Echo "AFTER_DISKINFO=1" >SYS:m5b1-after-diskinfo.txt
SYS:AmiInternalsTest/BootInfo >SYS:m5b1-bootinfo.txt
SYS:C/Echo $RC >SYS:m5b1-bootinfo-rc.txt
SYS:C/Echo "AFTER_BOOTINFO=1" >SYS:m5b1-after-bootinfo.txt
SYS:AmiInternalsTest/ROMInfo >SYS:m5b1-rominfo.txt
SYS:C/Echo $RC >SYS:m5b1-rominfo-rc.txt
SYS:C/Echo "AFTER_ROMINFO=1" >SYS:m5b1-after-rominfo.txt
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
  local out="$aros_root/m5b1-$key.txt" rcfile="$aros_root/m5b1-$key-rc.txt" after="$aros_root/m5b1-after-$key.txt" rc
  [[ -f "$out" && -f "$rcfile" && -f "$after" ]] || { echo FAIL; return; }
  rc="$(tr -d '\r\n ' < "$rcfile")"
  if [[ "$rc" == 0 ]] && grep -q "$title 0.1" "$out" && grep -q 'AmiInternals - Ploos AS' "$out" && grep -q "$marker" "$out"; then echo PASS; else echo FAIL; fi
}

diskinfo_status=$(check_rc0 diskinfo DiskInfo 'BlockSize')
bootinfo_status=$(check_rc0 bootinfo BootInfo 'ColdCapture')
rominfo_status=$(check_rc0 rominfo ROMInfo 'Version')
status=FAIL
if [[ "$diskinfo_status" == PASS && "$bootinfo_status" == PASS && "$rominfo_status" == PASS ]]; then status=PASS; fi

{
  echo "STATUS=$status"
  echo 'GATE=M5_BATCH1_AROS_GUEST'
  echo 'MODEL=A1200'
  echo 'KICKSTART=internal'
  echo "FS_UAE_EXIT=$fs_rc"
  echo "DISKINFO_STATUS=$diskinfo_status"
  echo "BOOTINFO_STATUS=$bootinfo_status"
  echo "ROMINFO_STATUS=$rominfo_status"
  echo 'QUALIFICATION=AROS_SMOKE_ONLY_KICKSTART_1_2_RUNTIME_STILL_REQUIRED'
  for key in diskinfo bootinfo rominfo; do
    [[ -f "$aros_root/m5b1-$key.txt" ]] && tr -d '\r' < "$aros_root/m5b1-$key.txt" | sed "s/^/GUEST_${key^^}=/"
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
