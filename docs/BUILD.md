# Build and qualification

AmiInternals uses `m68k-amigaos-gcc` and targets a plain Motorola 68000.

## Build

```sh
make clean
make check-config
make
```

The build uses `-m68000` and `-noixemul` for both compilation and linking. The latter is deliberate: core AmiInternals utilities must not acquire an ixemul.library runtime dependency.

## CI qualification

GitHub Actions uses a pinned Bebbo cross-compiler image to produce the native `Info` binary. A separate FS-UAE workflow then boots the AROS m68k system using FS-UAE's internal AROS Kickstart replacement, installs the produced `Info` binary into the guest filesystem, executes it during startup, and records output and return-code evidence.

This AROS/FS-UAE gate is an **initial runtime qualification**. It proves that the native executable can be loaded and executed in a real m68k Amiga-style guest environment, but it does not by itself prove Kickstart 1.2 compatibility.

## Kickstart 1.2 qualification

The project minimum remains Kickstart / AmigaOS 1.2 on a Motorola 68000. Final compatibility qualification will be performed locally against the real 1.2 environment, preferably in batches after several utilities are ready. The same local pass should also cover selected later AmigaOS releases to verify forward compatibility.

The commonly documented Bebbo GCC `-mcrt=nix13` startup option targets Kickstart 1.3. AmiInternals therefore does not use that option as evidence for 1.2 compatibility. If the default no-ixemul startup proves incompatible with 1.2, the project will provide a minimal 1.2-compatible startup path rather than raising the minimum OS version.
