# AmiInternals roadmap

## M0 — Foundation

Goal: establish the compatibility contract and repository architecture.

- [x] Define AmigaOS / Kickstart 1.2 minimum
- [x] Define Motorola 68000 minimum
- [x] Establish short utility naming
- [x] Establish read-only-first philosophy
- [x] Define initial tool catalogue
- [ ] Select and qualify the m68k Amiga compiler/toolchain
- [ ] Add reproducible build entry point
- [ ] Add common compatibility layer
- [ ] Produce first native 1.2-targeted binary

## M1 — Core inspection

`Info`, `Mem`, `Tasks`, `Ports`, `Libs`, `Devices`, `Resources`, `Residents`.

These establish most safe Exec-list traversal and formatting primitives used by later tools.

## M2 — DOS and filesystem

`DF`, `DU`, `Find`, `Which`, `Tree`, `Assigns`, `Mounts`, `Env`, `Head`, `Tail`, `Hex`, `Strings`.

## M3 — Deep system inspection

`TaskInfo`, `ExecInfo`, `Interrupts`, `Vectors`, `Patches`, `Alerts`, `Handlers`, `InputInfo`.

Version-sensitive structure access must be isolated and documented.

## M4 — Diagnostics

`Doctor`, `Snapshot`, `SnapDiff`, `Timer`, `Bench`, `WatchTask`, `WatchPort`, `WatchMem`.

Snapshot output should be stable and text-oriented so it can be diffed on real machines and in emulator qualification.

## M5 — Disk and boot

`DiskInfo`, `BootInfo`, `BootSave`, `BootRestore`, `TrackInfo`, `FloppyTest`, `DiskCheck`, `ROMInfo`.

Read-only inspection comes first. Write-capable utilities must require an explicit action.

## M6 — ARexx inspection

`RexxPorts`, `RexxSend`, `RexxProbe`.

ARexx support is optional at runtime and must not raise the minimum OS requirement for the rest of the suite.

## Qualification matrix

Hard compatibility gate:

- A500-class / 68000 / Kickstart 1.2

Forward-compatibility qualification:

- 68000 / Kickstart 1.3
- 68020+ / AmigaOS 2.x
- 68020+ / AmigaOS 3.0/3.1
- Later classic AmigaOS releases where practical

A feature unavailable on an older OS should degrade gracefully instead of raising the global minimum version.
