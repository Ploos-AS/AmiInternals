# Local AmigaOS 1.2 qualification

Requires FS-UAE, a visible X11/Xwayland session, `xwininfo`, libXcomposite, Python 3/Pillow,
amitools `xdftool`, and the local Bebbo `m68k-amigaos-gcc` toolchain on PATH.
No system media is downloaded. Supply your own licensed media.

## Current batch — Q3

Q1 (`Info`, `Mem`, `Tasks`) and Q2 (`Ports`, `Libs`, `Devices`) have passed the real AmigaOS 1.2 hard gate. Q3 completes M1 with the two remaining tools: `Resources` and `Residents`. It intentionally does not mix an M2 tool into the M1 batch.

From the repository root:

```sh
git pull --ff-only
bash ci/qualification/build-q3.sh
python3 ci/qualification/run-q3.py \
  --rom "$HOME/Documents/FS-UAE/Kickstarts/amiga-os-120.rom" \
  --workbench "$HOME/Documents/FS-UAE/Floppies/amiga-os-120-workbench.adf" \
  --out build/qualification/q3
```

See `ci/qualification/Q3.md` for the exact Q3 PASS criteria and verdict format.

## Harness rules

The output directory must be new. A failure stops the batch before the next tool.
Each tool gets a fresh boot with the same A500/68000/OCS/PAL profile, 512 KiB Chip
RAM, no other RAM, FPU or JIT, and real CPU speed. Binaries are built on the host,
copied into a private Workbench floppy, then read back and hash-checked before boot.
No guest compiler, replacement shell, DOS or filesystem is used.

The supported disk is the locally verified Amiga Forever Workbench 1.2 V33.56
edition (SHA-256 recorded in the scripts). A different disk must be identified
independently before adding its identity to the harness. The ROM is identified
against FS-UAE's documented KS1.2 fingerprint. Encrypted Amiga Forever ROMs use
the existing adjacent `rom.key`; decrypted bytes are used only in memory for
identification, never written or logged.

Original system media is never modified. Private writable Workbench copies stay
in `/tmp/amiinternals-q*-*`, outside the checkout; do not distribute these folders.
Evidence, config files, output, hashes and emulator screenshots go in ignored
`build/qualification/`. No ROM or copyrighted system executables belong in Git.

The replacement startup-sequence uses the original 1.2 CLI and commands. A small
host-built observation command records the preceding CLI return code and DOS
version. Inspect the full output, screenshot when available, and resolved emulator
configuration alongside the automated assertions. The bounded run is terminated
by the host after observation; emulator termination itself is not a guest return code.

The qualified tools use a minimal CLI startup instead of libnix's default automatic
library initialization, which attempts to open `utility.library` before `main`.
Only `dos.library` version 0 is opened. `-lnix13` supplies integer division/modulo
helpers, not startup or a replacement system library; the linked helpers use 68000
integer instructions. The archive name is not compatibility evidence: the actual
executable must pass on the complete AmigaOS 1.2 system.

## Previous batches

Q1 command:

```sh
bash ci/qualification/build-q1.sh && python3 ci/qualification/run-q1.py \
  --rom "$HOME/Documents/FS-UAE/Kickstarts/amiga-os-120.rom" \
  --workbench "$HOME/Documents/FS-UAE/Floppies/amiga-os-120-workbench.adf" \
  --out build/qualification/q1-new
```

Q2 is documented in `ci/qualification/Q2.md`; its real-classic verdict is PASS.