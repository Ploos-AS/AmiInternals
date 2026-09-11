#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
out="${1:-build/qualification/native-q3}"
mkdir -p "$out"
m68k-amigaos-gcc --version > "$out/compiler-version.txt"
git rev-parse HEAD > "$out/source-head.txt"

common=(src/common/start_cli.S src/common/start_cli.c src/common/compat.c src/common/output.c)
flags=(-Iinclude -Os -Wall -Wextra -Werror -m68000 -msoft-float -fomit-frame-pointer -noixemul -nostdlib)
libs=(-lgcc -lnix13)

for spec in 'Resources:resources' 'Residents:residents'; do
  tool="${spec%%:*}"
  dir="${spec##*:}"
  m68k-amigaos-gcc "${flags[@]}" -o "build/$tool" "${common[@]}" "src/$dir/main.c" "${libs[@]}" >> "$out/build.log" 2>&1
  cp "build/$tool" "$out/$tool"
  file "build/$tool" | tee -a "$out/file.txt"
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

sha256sum build/Resources build/Residents | tee "$out/checksums.sha256"
echo 'PASS: native Q3 build and static startup/dependency checks' | tee "$out/result.txt"
