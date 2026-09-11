#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
out="${1:-build/qualification/native-q4-arg-probe}"
mkdir -p "$out"

flags=(-Iinclude -Os -Wall -Wextra -Werror -m68000 -msoft-float -fomit-frame-pointer -noixemul -nostdlib)
libs=(-lgcc -lnix13)

m68k-amigaos-gcc --version > "$out/compiler-version.txt"
git rev-parse HEAD > "$out/source-head.txt"

# Known-good argument-free startup control (same startup family already qualified
# by Q1-Q3 on genuine Kickstart/Workbench 1.2).
m68k-amigaos-gcc "${flags[@]}" -o build/Q4Control \
  src/common/start_cli.S src/common/start_cli.c src/common/output.c \
  ci/qualification/q4_control_probe.c "${libs[@]}" \
  > "$out/control-build.log" 2>&1

# Startup under investigation: preserves the DOS CLI command line and builds
# argc/argv without ReadArgs(), utility.library, ixemul, or libnix startup.
m68k-amigaos-gcc "${flags[@]}" -o build/Q4ArgProbe \
  src/common/start_cli_args.S src/common/start_cli_args.c src/common/output.c \
  ci/qualification/q4_arg_probe.c "${libs[@]}" \
  > "$out/arg-build.log" 2>&1

for bin in Q4Control Q4ArgProbe; do
  file "build/$bin" > "$out/$bin-file.txt"
  m68k-amigaos-nm "build/$bin" > "$out/$bin-symbols.txt"
  m68k-amigaos-objdump -d "build/$bin" > "$out/$bin-disassembly.txt"
  if grep -Eq ' [Uu] |___initlibraries|___initcpp' "$out/$bin-symbols.txt"; then
    echo "FAIL: $bin has unresolved symbols or automatic runtime initialization" >&2
    exit 1
  fi
  if strings "build/$bin" | grep -Eq 'utility.library|ixemul.library'; then
    echo "FAIL: $bin has newer runtime dependency" >&2
    exit 1
  fi
done

sha256sum build/Q4Control build/Q4ArgProbe | tee "$out/checksums.sha256"
echo 'PASS: Q4 control + argument startup probe native build' | tee "$out/result.txt"
