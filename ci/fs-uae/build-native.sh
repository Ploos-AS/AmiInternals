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

echo 'STEP=native-compile'
rm -f build/Info
set +e
timeout "${BUILD_TIMEOUT}s" docker run --rm \
  -v "$PWD:/work" \
  -w /work \
  "$IMAGE" \
  m68k-amigaos-gcc \
    -Iinclude \
    -Os -Wall -Wextra -Werror -m68000 -fomit-frame-pointer -noixemul \
    -o build/Info \
    src/common/compat.c \
    src/common/output.c \
    src/info/main.c \
    -noixemul
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "ERROR: native compile failed or timed out (rc=$rc)" >&2
  exit "$rc"
fi

echo 'STEP=validate-output'
test -s build/Info
cp build/Info "$OUT_DIR/Info"
file "$OUT_DIR/Info" | tee "$OUT_DIR/file.txt"
sha256sum "$OUT_DIR/Info" | tee "$OUT_DIR/Info.sha256"

if ! grep -Eiq 'AmigaOS|Amiga.*executable|loadseg' "$OUT_DIR/file.txt"; then
  echo "ERROR: native output is not recognized as an Amiga executable" >&2
  exit 1
fi

printf 'STATUS=PASS\nGATE=M0_3_NATIVE_BEBBO_BUILD\nIMAGE=%s\nBINARY=%s\n' \
  "$IMAGE" "$OUT_DIR/Info" | tee "$OUT_DIR/result.txt"
