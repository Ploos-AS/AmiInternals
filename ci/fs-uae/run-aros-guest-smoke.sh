#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-guest}"
SYSTEM_DIR="build/fs-uae/aros-system"
mkdir -p "$OUT_DIR"

if [[ ! -f build/fs-uae/native/Info ]]; then
  echo "ERROR: native Info binary missing; run build-native.sh first" >&2
  exit 1
fi

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
cp "$startup" "$startup.amiinternals-original"

cat > "$startup" <<'EOF'
SYS:C/Echo "AMIINTERNALS_GUEST_STARTED=1" >SYS:amiinternals-started.txt
SYS:C/Echo "AMIINTERNALS_BEFORE_INFO=1" >SYS:amiinternals-before.txt
SYS:Info >SYS:amiinternals-info.txt
SYS:C/Echo $RC >SYS:amiinternals-rc.txt
SYS:C/Echo "AMIINTERNALS_AFTER_INFO=1" >SYS:amiinternals-after.txt
SYS:C/Execute SYS:S/Startup-Sequence.amiinternals-original
EOF

rm -f "$aros_root"/amiinternals-{started,before,info,rc,after}.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

info_out="$aros_root/amiinternals-info.txt"
guest_rc="$aros_root/amiinternals-rc.txt"
after="$aros_root/amiinternals-after.txt"
status=FAIL
observation=guest_result_missing

if [[ -f "$after" && -f "$info_out" ]] && grep -q 'Info 0.1' "$info_out" && grep -q 'AmiInternals - Ploos AS' "$info_out"; then
  status=PASS
  observation=guest_executed_native_info
elif [[ -f "$after" ]]; then
  observation=guest_executed_info_but_output_mismatch
elif [[ -f "$aros_root/amiinternals-before.txt" ]]; then
  observation=guest_started_info_but_did_not_return
fi

{
  echo "STATUS=$status"
  echo "GATE=M0_3_AROS_GUEST_EXECUTION"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "OBSERVATION=$observation"
  if [[ -f "$guest_rc" ]]; then
    tr -d '\r' < "$guest_rc" | sed 's/^/GUEST_RC=/'
  fi
  if [[ -f "$info_out" ]]; then
    tr -d '\r' < "$info_out" | sed 's/^/GUEST_INFO=/'
  fi
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
