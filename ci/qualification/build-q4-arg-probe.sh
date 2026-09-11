#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
out="${1:-build/qualification/native-q4-arg-probe}"
mkdir -p "$out"

flags=(-Iinclude -Os -Wall -Wextra -Werror -m68000 -msoft-float -fomit-frame-pointer -noixemul -nostdlib)
common=(src/common/start_cli_args.S src/common/start_cli_args.c src/common/output.c)
libs=(-lgcc -lnix13)

m68k-amigaos-gcc --version > "$out/compiler-version.txt"
git rev-parse HEAD > "$out/source-head.txt"

m68k-amigaos-gcc "${flags[@]}" -o build/Q4ArgProbe \
  "${common[@]}" ci/qualification/q4_arg_probe.c "${libs[@]}" \
  > "$out/build.log" 2>&1

file build/Q4ArgProbe | tee "$out/file.txt"
m68k-amigaos-nm build/Q4ArgProbe > "$out/symbols.txt"
m68k-amigaos-objdump -d build/Q4ArgProbe > "$out/disassembly.txt"

if grep -Eq ' [Uu] |___initlibraries|___initcpp' "$out/symbols.txt"; then
  echo 'FAIL: unresolved symbols or automatic runtime initialization' >&2
  exit 1
fi
if strings build/Q4ArgProbe | grep -Eq 'utility.library|ixemul.library'; then
  echo 'FAIL: newer runtime dependency' >&2
  exit 1
fi

sha256sum build/Q4ArgProbe | tee "$out/checksum.sha256"
echo 'PASS: Q4 argument startup probe native build' | tee "$out/result.txt"
