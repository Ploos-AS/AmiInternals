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
  timeout "${BUILD_TIMEOUT}s" docker run --rm \
    -v "$PWD:/work" \
    -w /work \
    "$IMAGE" \
    m68k-amigaos-gcc \
      -Iinclude \
      -Os -Wall -Wextra -Werror -m68000 -fomit-frame-pointer -noixemul \
      -o "build/$tool" \
      src/common/compat.c \
      src/common/output.c \
      "$source" \
      -noixemul
  rc=$?
  set -e
  if [[ $rc -ne 0 ]]; then
    echo "ERROR: native compile for $tool failed or timed out (rc=$rc)" >&2
    exit "$rc"
  fi
}

compile_tool Info src/info/main.c
compile_tool Mem src/mem/main.c
compile_tool Tasks src/tasks/main.c
compile_tool Libs src/libs/main.c
compile_tool Ports src/ports/main.c
compile_tool Devices src/devices/main.c
compile_tool Resources src/resources/main.c

echo 'STEP=validate-output'
: > "$OUT_DIR/files.txt"
: > "$OUT_DIR/checksums.sha256"
for tool in Info Mem Tasks Libs Ports Devices Resources; do
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

printf 'STATUS=PASS\nGATE=M0_7_M0_9_NATIVE_BEBBO_BATCH\nIMAGE=%s\nBINARY_INFO=%s\nBINARY_MEM=%s\nBINARY_TASKS=%s\nBINARY_LIBS=%s\nBINARY_PORTS=%s\nBINARY_DEVICES=%s\nBINARY_RESOURCES=%s\n' \
  "$IMAGE" "$OUT_DIR/Info" "$OUT_DIR/Mem" "$OUT_DIR/Tasks" "$OUT_DIR/Libs" "$OUT_DIR/Ports" "$OUT_DIR/Devices" "$OUT_DIR/Resources" | tee "$OUT_DIR/result.txt"
