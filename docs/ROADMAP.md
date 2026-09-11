# AmiInternals roadmap

## M0 — Foundation

Goal: establish the compatibility contract and repository architecture.

- [x] Define AmigaOS / Kickstart 1.2 minimum
- [x] Define Motorola 68000 minimum
- [x] Establish short utility naming
- [x] Establish read-only-first philosophy
- [x] Define initial tool catalogue
- [x] Select and qualify the m68k Amiga compiler/toolchain
- [x] Add reproducible build entry point
- [x] Add common compatibility layer
- [x] Produce first native 1.2-targeted binary

Native Bebbo/m68k-amigaos-gcc builds and FS-UAE/AROS smoke gates are automated in CI. AROS smoke is supporting evidence only; it does not replace the hard real-classic Kickstart 1.2 qualification gate below.

## M1 — Core inspection

`Info`, `Mem`, `Tasks`, `Ports`, `Libs`, `Devices`, `Resources`, `Residents`.

These establish most safe Exec-list traversal and formatting primitives used by later tools.

**CI status:** complete (native 68000 build + FS-UAE/AROS smoke).

## M2 — DOS and filesystem

`DF`, `DU`, `Find`, `Which`, `Tree`, `Assigns`, `Mounts`, `Env`, `Head`, `Tail`, `Hex`, `Strings`.

**CI status:** complete (native 68000 build + FS-UAE/AROS smoke).

## M3 — Deep system inspection

`TaskInfo`, `ExecInfo`, `Interrupts`, `Vectors`, `Patches`, `Alerts`, `Handlers`, `InputInfo`.

Version-sensitive structure access must be isolated and documented.

**CI status:** complete (native 68000 build + FS-UAE/AROS smoke). Real-classic structure semantics remain part of the Kickstart 1.2 qualification gate.

## M4 — Diagnostics

`Doctor`, `Snapshot`, `SnapDiff`, `Timer`, `Bench`, `WatchTask`, `WatchPort`, `WatchMem`.

Snapshot output should be stable and text-oriented so it can be diffed on real machines and in emulator qualification.

**CI status:** complete (native 68000 build + FS-UAE/AROS smoke).

## M5 — Disk and boot

`DiskInfo`, `BootInfo`, `BootSave`, `BootRestore`, `TrackInfo`, `FloppyTest`, `DiskCheck`, `ROMInfo`.

Read-only inspection comes first. Write-capable utilities must require an explicit action.

**CI status:** complete (native 68000 build + FS-UAE/AROS smoke). `BootRestore` CI exercises only refusal/safety paths; raw boot-block write/read-back and physical or disposable classic floppy qualification remain intentionally outside AROS smoke.

## M6 — ARexx inspection

`RexxPorts`, `RexxSend`, `RexxProbe`.

ARexx support is optional at runtime and must not raise the minimum OS requirement for the rest of the suite.

**CI status:** complete (native 68000 build + FS-UAE/AROS smoke). `RexxPorts` and `RexxProbe` observe public Exec message ports and do not by themselves prove ARexx capability. `RexxSend` must degrade gracefully when `rexxsyslib.library` is unavailable; a successful live ARexx exchange still requires real AmigaOS 2.x+ qualification with ARexx/RexxMast active.

## v0.1.0 hardening

**Status: complete.** The M1–M6 source review and defensive-hardening pass is complete. Changes include bounded Exec/DOS list traversal, safer snapshots of volatile system state, explicit truncation/error reporting, output-write checking, stronger disk/boot safety handling, and corrected ARexx result handling. Current-head native 68000 build and full FS-UAE/AROS Gate 1–12 regression are green after the M6 hardening changes.

No hardening review replaces real classic validation. In particular, version-sensitive ExecBase/task/vector semantics, classic DOS behavior, raw trackdisk I/O, and successful live ARexx exchange remain qualification work.

**v0.1.0 implementation status:** complete. The full M1–M6 catalogue contains 47 tools and is covered by the automated native 68000 build and FS-UAE/AROS smoke gates. Hardening is also complete. The remaining release blocker is the real-classic qualification matrix below.

## v0.1.0 real-classic qualification

**Status: next release gate.** Qualification should be performed in small batches, normally three tools at a time, with the A500-class / 68000 / Kickstart 1.2 target treated as the hard compatibility gate.

Qualification must distinguish between:

- **hard baseline:** A500-class / 68000 / Kickstart 1.2;
- **forward compatibility:** Kickstart 1.3, AmigaOS 2.x, and AmigaOS 3.0/3.1;
- **feature-gated behavior:** functionality inherently absent from older releases must fail gracefully rather than raising the suite-wide minimum OS version.

Special qualification items include:

- M3: verify real-classic ExecBase, task, interrupt/vector and related structure semantics;
- M4: verify timing/watch/snapshot behavior on classic DOS/Exec;
- M5: verify classic DOS metadata behavior and manual trackdisk paths; exercise `BootRestore` only against a disposable image/floppy and confirm write-back verification;
- M6: verify graceful ARexx absence on the 1.x baseline and a successful `RexxSend` exchange on AmigaOS 2.x+ with RexxMast active.

## v0.2 — Extended inspection candidates

After the v0.1.0 catalogue has completed real-classic qualification and hardening, extend AmiInternals with additional focused inspection tools. The v0.2 candidates are:

- `OpenFiles` / `Locks` — inspect open files and DOS locks where safely observable.
- `Signals` — inspect task signal allocation/state without modifying it.
- `Semaphores` — inspect public Exec semaphores and ownership/wait state where available.
- `MemoryMap` — summarize memory regions, headers and allocation characteristics exposed by classic Exec.
- `Modules` — inspect loaded/resident modules with more detail than the v0.1.0 resident overview.
- `CLIInfo` — inspect CLI/process state and command environment.
- `ProcessTree` — present CLI/process relationships where they can be derived safely.
- `DeviceInfo` — detailed inspection of a selected Exec device.
- `LibraryInfo` — detailed inspection of a selected Exec library.
- `PortInfo` — detailed inspection of a selected public message port.
- `DOSPackets` — inspect DOS packet/handler state where this can be done defensively and read-only.
- `Volumes` — detailed mounted-volume inspection beyond `DF`/`Mounts`.
- `StartupInfo` — inspect startup/boot environment and relevant configuration state.
- `CrashInfo` — collect read-only crash/alert diagnostic context where available.

These are v0.2 candidates, not requirements for v0.1.0. The same compatibility policy applies: Motorola 68000 and Kickstart 1.2 remain the suite baseline unless a feature is inherently unavailable there, in which case it must degrade gracefully and be runtime-gated.

## Qualification matrix

Hard compatibility gate:

- A500-class / 68000 / Kickstart 1.2

Forward-compatibility qualification:

- 68000 / Kickstart 1.3
- 68020+ / AmigaOS 2.x
- 68020+ / AmigaOS 3.0/3.1
- Later classic AmigaOS releases where practical

A feature unavailable on an older OS should degrade gracefully instead of raising the global minimum version.
