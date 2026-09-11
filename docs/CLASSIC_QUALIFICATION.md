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

Status: **READY FOR LOCAL QUALIFICATION**

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
