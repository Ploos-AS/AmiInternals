# AmiInternals real-classic qualification

This is the release qualification track for v0.1.0. CI's FS-UAE/AROS smoke remains supporting evidence only; it is not proof of AmigaOS 1.2 compatibility.

## Rules

- Hard gate: real AmigaOS 1.2 environment on an A500-class machine with Motorola 68000, genuine Kickstart 1.2 ROM, and matching Workbench/AmigaDOS 1.2 system environment.
- Kickstart 1.2 by itself is not sufficient for the hard gate; the guest must also boot and run the tools in the matching Workbench/AmigaDOS 1.2 environment.
- AROS never counts as the AmigaOS 1.2 hard gate. It remains CI smoke/regression evidence only.
- Run the exact binaries built from the recorded commit.
- Do not replace failures with AROS results.
- Record emulator/hardware model, CPU, ROM version, Workbench/DOS version, memory configuration, commit SHA and binary hashes.
- A crash, hang, Guru, corrupt output, invalid memory access, or dependency on APIs unavailable on AmigaOS 1.2 is a FAIL.
- A tool may expose less information on an older OS only when that limitation is intentional and graceful.
- Qualification is normally performed in batches of three tools.
- Keep the first pass read-only. Destructive disk qualification is handled separately with disposable media.

## Matrix

1. **Hard gate:** A500-class / 68000 / Kickstart 1.2 + Workbench/AmigaDOS 1.2
2. 68000 / Kickstart 1.3 + matching Workbench/AmigaDOS 1.3
3. 68020+ / AmigaOS 2.x
4. 68020+ / AmigaOS 3.0/3.1

A batch is not considered release-qualified until the full AmigaOS 1.2 hard gate passes. Forward rows may be completed after the hard gate unless a tool requires a newer facility by design (for example live ARexx exchange).

---

# Q1 — M1 batch 1: Info, Mem, Tasks

Status: **PASS — real AmigaOS 1.2 qualification completed**

Target commit: record the current `main` SHA immediately before building and keep that SHA with the evidence.

## Build preparation

From a clean checkout:

```sh
git checkout main
git pull --ff-only
git status --short
git rev-parse HEAD
make clean
make
sha256sum Info Mem Tasks
file Info Mem Tasks
```

If the project Makefile places binaries in another directory, use those exact produced binaries and record their SHA-256 values. Do not rebuild inside the guest with another compiler.

## Required AmigaOS 1.2 machine profile

Use a visible A500-class FS-UAE profile or equivalent real hardware:

- CPU: 68000
- Kickstart: genuine 1.2 ROM owned by the tester
- Workbench/AmigaDOS: genuine matching 1.2 system environment owned by the tester
- no JIT
- no accelerator
- baseline Chip RAM configuration representative of an A500
- no Fast RAM required for the hard gate

The hard gate is the complete AmigaOS 1.2 environment. A Kickstart 1.2 ROM combined with AROS, Workbench 1.3, Workbench 2.x, or another replacement DOS/system environment does not qualify as AmigaOS 1.2.

Additional memory configurations may be tested after the baseline, but they do not replace it.

Copy `Info`, `Mem`, and `Tasks` to a writable test volume/drawer without replacing system commands.

## Q1.1 — Info

Run:

```text
Info
```

PASS requirements:

- process starts and exits normally with RC 0;
- banner identifies `Info 0.1`;
- Exec version is plausible for the booted AmigaOS 1.2 system;
- Chip free/largest and total free/largest values are numeric and plausible;
- Fast memory values are zero or otherwise consistent with the configured machine;
- no Guru, hang, requester storm, or corrupted text.

Evidence to retain: complete console output and one screenshot.

## Q1.2 — Mem

Run:

```text
Mem
```

PASS requirements:

- process starts and exits normally with RC 0;
- banner identifies `Mem 0.1`;
- Chip, Fast and All groups are printed;
- `Largest` never exceeds the corresponding `Free` value;
- `Fragmented` is not an obvious unsigned underflow value;
- Fast figures are consistent with the configured machine;
- no Guru, hang, or corrupted output.

Cross-check the rough free-memory magnitude against `Info` from the same boot session. Exact equality is not required because running commands changes free memory.

Evidence to retain: complete console output and one screenshot.

## Q1.3 — Tasks

Run:

```text
Tasks
```

PASS requirements:

- process starts and exits normally with RC 0;
- banner identifies `Tasks 0.1`;
- header `State Pri Name` is present;
- at least the current/running task is represented;
- listed state labels are limited to RUN/READY/WAIT;
- priorities and names are readable and structurally plausible;
- no traversal loop, hang, Guru, or corrupted task name output;
- if more than 64 tasks are present, truncation is reported rather than writing past the fixed snapshot.

The AmigaOS 1.2 pass is specifically evidence that direct `ExecBase` `ThisTask`, `TaskReady`, `TaskWait`, and task-node fields used by this implementation behave as assumed on the hard-gate system.

Evidence to retain: complete console output and one screenshot.

## Batch verdict

Record the result in this form:

```text
AmiInternals Q1 / M1 batch 1
Commit: <sha>
Machine/emulator: <value>
CPU: 68000
Kickstart: 1.2 <exact ROM/version if known>
Workbench/AmigaDOS: 1.2 <exact version if known>
Chip RAM: <value>
Fast RAM: <value>
Info SHA256: <sha256>
Mem SHA256: <sha256>
Tasks SHA256: <sha256>
Info: PASS|FAIL
Mem: PASS|FAIL
Tasks: PASS|FAIL
Unexpected Guru/hang: NO|YES
Overall: PASS|FAIL
Notes: <free text>
```

If any tool fails, stop the batch, preserve the exact failing output/state, and fix the implementation before qualifying later batches from a newer commit.

## After Q1 passes

The next batch is M1 batch 2: `Ports`, `Libs`, `Devices`. It will focus on safe classic Exec public-list traversal and snapshot semantics.

## Q1 / M1 batch 1 evidence (2026-09-11)

The first batch was run sequentially from commit `25c24b856296d22872d3675c2ca9e85dcbe09201` after the initial pre-`main` startup failure was fixed with a minimal 1.2 CLI startup. Each tool used a fresh visible FS-UAE session and the exact host binary copied to a private writable copy of the local Workbench disk. The guest returned RC 0, then the observation command recorded DOS 33.124. No Guru, hang, requester storm, or corrupted output occurred.

Machine profile: FS-UAE 3.2.35, A500, OCS/PAL, Motorola 68000, real CPU speed, 512 KiB Chip RAM, 0 Fast/Slow RAM, FPU disabled, JIT disabled. FS-UAE logs report `KS ROM v1.2 (A500,A1000,A2000) rev 33.180 (256k) [315093-01]` and `CPU=68000, FPU=0, MMU=0, JIT=0`.

ROM: `/home/pgo/Documents/FS-UAE/Kickstarts/amiga-os-120.rom`, 262155 bytes, SHA-256 `781a36914b49642ab14b5a6f1e7263c7fc2dcbaba3c1fc141a163fd5299b976d`; identified as genuine Kickstart 1.2 revision 33.180 (decrypted SHA-1 `11f9e62cf299f72184835b7b2a70a16333fc0d88`, FS-UAE CRC32 `a6ce1636`). Matching system disk: local Workbench/AmigaDOS 1.2 V33.56 `amiga-os-120-workbench.adf`, SHA-256 `1035a9a317fbbf0056848a25397f245967d7a8f1bc5079b02a018f410899bdf0`.

| Tool | SHA-256 | Result |
|---|---|---|
| Info | `ad549e74b6de1e6a1f3e433750d389f7d7659212dc27a785912a50f097309c29` | PASS — real Kickstart 1.2 |
| Mem | `4891d9c7ee0fb4107421307509e4238110d0e9ba3db697214aac76bfd87a8a62` | PASS — real Kickstart 1.2 |
| Tasks | `770a29124ae40684e78bf26d5f82e2f319d9338b0a181b1bd0ab9ca01a8e2afa` | PASS — real Kickstart 1.2 |

Q1/M1 batch 1: **PASS — real Kickstart 1.2 + matching Workbench/AmigaDOS 1.2**.

Evidence is retained under `build/qualification/q1/final/` (metadata, full captured output, status/return output, FS-UAE logs/configuration and screenshots). This is a local ignored runtime area; no ROM or system disk is committed. Native Q1 build/static gates passed via `ci/qualification/build-q1.sh`. The corrected existing AROS smoke/regression scripts all returned zero and all reported tool statuses PASS; those results remain supporting evidence only and are not used for the AmigaOS 1.2 verdict.
