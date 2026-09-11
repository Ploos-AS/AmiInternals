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

The default no-ixemul startup failed the first real AmigaOS 1.2 run before `Info` reached `main`, with `utility.library failed to load`. `Info`, `Mem`, and `Tasks` now use the minimal argument-free CLI startup in `src/common/start_cli.S` and `src/common/start_cli.c`. It opens only `dos.library` with version 0 and returns the tool's result to the original CLI. Workbench icon launches are rejected after replying to the startup message.

These three tools link with `-nostdlib -lgcc -lnix13`. The archive supplies only the integer division/modulo helpers needed for decimal output; it does not provide the startup. The linked helpers were inspected as 68000 integer code. Neither the archive name nor the commonly documented `-mcrt=nix13` option is evidence for 1.2 compatibility: qualification must execute the actual binary in the complete real AmigaOS 1.2 environment. Other tools retain their existing runtime pending their own qualification.

See `ci/qualification/README.md` for the local Q1 build and visible FS-UAE harness. It never downloads ROM or Workbench media.
