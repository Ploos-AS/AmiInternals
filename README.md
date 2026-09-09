# AmiInternals

AmiInternals is a compact system-inspection and diagnostics suite for classic AmigaOS, inspired by the philosophy of Sysinternals: small focused tools, deep visibility, and safe read-only inspection by default.

## Baseline

- Minimum target: Kickstart / AmigaOS 1.2
- CPU baseline: Motorola 68000
- Forward-compatible with later AmigaOS releases where the underlying APIs permit it
- No FPU requirement
- No ixemul or other runtime dependency
- CLI-first; individual tools should be small enough to live in `C:`
- Newer OS functionality must be detected at runtime rather than becoming a hard requirement
- Inspection is read-only by default; modifying tools must be explicit and isolated

## Planned tools

### Core system
`Info`, `Mem`, `Uptime`, `Tasks`, `TaskInfo`, `Ports`, `Libs`, `Devices`, `Resources`, `Residents`, `ExecInfo`, `Interrupts`, `Vectors`, `Patches`, `Alerts`, `Handlers`, `InputInfo`.

### DOS / filesystem
`DF`, `DU`, `Find`, `Which`, `Tree`, `Assigns`, `Mounts`, `Env`, `Head`, `Tail`, `Hex`, `Strings`.

### Diagnostics
`Doctor`, `Snapshot`, `SnapDiff`, `Timer`, `Bench`, `WatchTask`, `WatchPort`, `WatchMem`.

### Disk / boot
`DiskInfo`, `BootInfo`, `BootSave`, `BootRestore`, `TrackInfo`, `FloppyTest`, `DiskCheck`, `ROMInfo`.

### ARexx
`RexxPorts`, `RexxSend`, `RexxProbe`.

The short utility names intentionally do not carry an `Ami` prefix. The suite identity is AmiInternals.

## Milestones

See [docs/ROADMAP.md](docs/ROADMAP.md).

## Development rule

AmiInternals treats AmigaOS 1.2 compatibility as an architectural constraint, not a later porting exercise. Code shared by all tools should use the oldest practical Exec/DOS interfaces. Features introduced by newer OS releases belong behind runtime checks.
