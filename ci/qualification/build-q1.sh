#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
out="${1:-build/qualification/native-q1}"
mkdir -p "$out"
m68k-amigaos-gcc --version > "$out/compiler-version.txt"
git rev-parse HEAD > "$out/source-head.txt"
make -B CC=m68k-amigaos-gcc \
  CFLAGS='-Os -Wall -Wextra -Werror -m68000 -msoft-float -fomit-frame-pointer -noixemul' \
  LDFLAGS='-m68000 -msoft-float -noixemul' info mem tasks > "$out/build.log" 2>&1
for tool in Info Mem Tasks; do
  cp "build/$tool" "$out/$tool"
  file "build/$tool"
  m68k-amigaos-nm "build/$tool" > "$out/$tool.symbols.txt"
  m68k-amigaos-objdump -d "build/$tool" > "$out/$tool.disassembly.txt"
  if grep -Eq ' [Uu] |___initlibraries|___initcpp' "$out/$tool.symbols.txt"; then
    echo "FAIL: unresolved symbols or automatic runtime initialization: $tool" >&2
    exit 1
  fi
  if strings "build/$tool" | grep -Eq 'utility.library|ixemul.library'; then
    echo "FAIL: newer runtime dependency: $tool" >&2
    exit 1
  fi
done
sha256sum build/Info build/Mem build/Tasks | tee "$out/checksums.sha256"
echo 'PASS: native Q1 build and static startup/dependency checks' | tee "$out/result.txt"
