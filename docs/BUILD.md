# Build and qualification

AmiInternals uses `m68k-amigaos-gcc` and targets a plain Motorola 68000.

## Build

```sh
make clean
make check-config
make
```

The build uses `-m68000` and `-noixemul` for both compilation and linking. The latter is deliberate: core AmiInternals utilities must not acquire an ixemul.library runtime dependency.

## CI scope

GitHub Actions performs a cross-build of `Info`, verifies that a non-empty executable is produced, and inspects the resulting object format with the m68k binutils tools.

A successful CI build proves build reproducibility only. It does **not** prove Kickstart 1.2 runtime compatibility.

## Kickstart 1.2 gate

The project minimum remains Kickstart / AmigaOS 1.2 on a Motorola 68000. That claim is accepted only after the produced binary has been executed successfully in the 1.2 qualification environment.

The commonly documented Bebbo GCC `-mcrt=nix13` startup option targets Kickstart 1.3. AmiInternals therefore does not use that option as evidence for 1.2 compatibility. If the default no-ixemul startup proves incompatible with 1.2, the project will provide a minimal 1.2-compatible startup path rather than raising the minimum OS version.
