# Local AmigaOS 1.2 Q1

Requires FS-UAE, a visible X11/Xwayland session, `xwininfo`, libXcomposite, Python 3/Pillow,
amitools `xdftool`, and the local Bebbo `m68k-amigaos-gcc` toolchain on PATH.
No system media is downloaded. Supply your own licensed media.

One-command build and sequential qualification (from the repository root):

```sh
bash ci/qualification/build-q1.sh && python3 ci/qualification/run-q1.py \
  --rom "$HOME/Documents/FS-UAE/Kickstarts/amiga-os-120.rom" \
  --workbench "$HOME/Documents/FS-UAE/Floppies/amiga-os-120-workbench.adf" \
  --out build/qualification/q1-new
```

The output directory must be new. A failure stops the batch before the next tool.
Each tool gets a fresh boot with the same A500/68000/OCS/PAL profile, 512 KiB Chip
RAM, no other RAM, FPU or JIT, and real CPU speed. Binaries are built on the host,
copied into a private Workbench floppy, then read back and hash-checked before boot.
No guest compiler, replacement shell, DOS or filesystem is used.

The supported disk is the locally verified Amiga Forever Workbench 1.2 V33.56
edition (SHA-256 recorded in the script). A different disk must be identified
independently before adding its identity to the harness. The ROM is identified
against FS-UAE's [documented KS1.2 fingerprint](https://fs-uae.net/docs/kickstart-roms/).
Encrypted Amiga Forever ROMs use the existing adjacent `rom.key`; decrypted bytes
are used only in memory for identification, never written or logged.

Original system media is never modified. Private writable Workbench copies stay
in `/tmp/amiinternals-q1-*`, outside the checkout; do not distribute these folders.
Evidence, config files, output, hashes and emulator screenshots go in ignored
`build/qualification/`. No ROM or copyrighted system executables belong in Git.

The replacement startup-sequence uses the original 1.2 CLI and commands. A small
host-built observation command records the preceding CLI return code and DOS
version. Inspect the full output, screenshot and resolved emulator configuration
alongside the automated assertions. The bounded run is terminated by the host
after observation; emulator termination itself is not a guest return code.

Q1 uses a minimal CLI startup instead of libnix's default automatic library
initialization, which attempts to open `utility.library` before `main`. Only
`dos.library` version 0 is opened. `-lnix13` supplies integer division/modulo
helpers, not startup or a replacement system library; the linked helpers use
68000 integer instructions. The name of that archive is not compatibility
evidence: the actual executable must pass on the complete AmigaOS 1.2 system.
Other tools retain their existing startup pending their own qualification.
