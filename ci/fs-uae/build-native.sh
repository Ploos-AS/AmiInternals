#!/usr/bin/env bash
set -euo pipefail

IMAGE="${AMIINTERNALS_BEBBO_IMAGE:-amigadev/m68k-amigaos-gcc@sha256:b18080e6ffca8f793e0f539536a9138e9d2a548ca1a301c7483f43ee15fedfed}"
OUT_DIR="${1:-build/fs-uae/native}"
PULL_TIMEOUT="${AMIINTERNALS_DOCKER_PULL_TIMEOUT:-180}"
BUILD_TIMEOUT="${AMIINTERNALS_DOCKER_BUILD_TIMEOUT:-120}"
mkdir -p "$OUT_DIR" build

printf 'IMAGE=%s\n' "$IMAGE"
printf 'PULL_TIMEOUT=%ss\n' "$PULL_TIMEOUT"
printf 'BUILD_TIMEOUT=%ss\n' "$BUILD_TIMEOUT"

echo 'STEP=docker-pull'
set +e
timeout "${PULL_TIMEOUT}s" docker pull "$IMAGE"
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "ERROR: docker pull failed or timed out (rc=$rc)" >&2
  exit "$rc"
fi

echo 'STEP=docker-inspect'
docker image inspect "$IMAGE" --format '{{join .RepoDigests "\n"}}' | tee "$OUT_DIR/toolchain-image.txt"

echo 'STEP=compiler-version'
timeout 30s docker run --rm "$IMAGE" m68k-amigaos-gcc --version | tee "$OUT_DIR/compiler-version.txt"

compile_tool() {
  local tool="$1"
  local source="$2"
  echo "STEP=native-compile-$tool"
  rm -f "build/$tool"
  set +e
  timeout "${BUILD_TIMEOUT}s" docker run --rm -v "$PWD:/work" -w /work "$IMAGE" \
    m68k-amigaos-gcc -Iinclude -Os -Wall -Wextra -Werror -m68000 -fomit-frame-pointer -noixemul \
    -o "build/$tool" src/common/compat.c src/common/output.c "$source" -noixemul
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "ERROR: native compile for $tool failed or timed out (rc=$rc)" >&2
    exit "$rc"
  fi
}

TOOLS=(Info Mem Tasks Libs Ports Devices Resources Residents Assigns Mounts DF DU Find Which Tree Env Head Tail Hex Strings TaskInfo ExecInfo Interrupts Vectors Patches Alerts Handlers InputInfo Doctor Snapshot SnapDiff Timer Bench WatchTask WatchPort WatchMem)
SOURCES=(src/info/main.c src/mem/main.c src/tasks/main.c src/libs/main.c src/ports/main.c src/devices/main.c src/resources/main.c src/residents/main.c src/assigns/main.c src/mounts/main.c src/df/main.c src/du/main.c src/find/main.c src/which/main.c src/tree/main.c src/env/main.c src/head/main.c src/tail/main.c src/hex/main.c src/strings/main.c src/taskinfo/main.c src/execinfo/main.c src/interrupts/main.c src/vectors/main.c src/patches/main.c src/alerts/main.c src/handlers/main.c src/inputinfo/main.c src/doctor/main.c src/snapshot/main.c src/snapdiff/main.c src/timer/main.c src/bench/main.c src/watchtask/main.c src/watchport/main.c src/watchmem/main.c)

for i in "${!TOOLS[@]}"; do
  compile_tool "${TOOLS[$i]}" "${SOURCES[$i]}"
done

echo 'STEP=validate-output'
: > "$OUT_DIR/files.txt"
: > "$OUT_DIR/checksums.sha256"
for tool in "${TOOLS[@]}"; do
  test -s "build/$tool"
  cp "build/$tool" "$OUT_DIR/$tool"
  file "$OUT_DIR/$tool" | tee -a "$OUT_DIR/files.txt"
  sha256sum "$OUT_DIR/$tool" | tee -a "$OUT_DIR/checksums.sha256"
  if ! file "$OUT_DIR/$tool" | grep -Eiq 'AmigaOS|Amiga.*executable|loadseg'; then
    echo "ERROR: $tool is not recognized as an Amiga executable" >&2
    exit 1
  fi
done

cp "$OUT_DIR/files.txt" "$OUT_DIR/file.txt"
sha256sum "$OUT_DIR/Info" > "$OUT_DIR/Info.sha256"

{
  echo 'STATUS=PASS'
  echo 'GATE=M4_COMPLETE_NATIVE_BEBBO'
  echo "IMAGE=$IMAGE"
  for tool in "${TOOLS[@]}"; do echo "BINARY_${tool^^}=$OUT_DIR/$tool"; done
} | tee "$OUT_DIR/result.txt"
