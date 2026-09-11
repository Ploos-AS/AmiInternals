#!/usr/bin/env python3
"""Isolate AmiInternals argc/argv startup on genuine AmigaOS 1.2 media."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import time


def command(*args):
    return subprocess.check_output([str(a) for a in args], stderr=subprocess.STDOUT)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    p = argparse.ArgumentParser(__doc__)
    p.add_argument('--rom', type=Path, required=True)
    p.add_argument('--workbench', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    p.add_argument('--seconds', type=int, default=90)
    args = p.parse_args()

    root = Path(__file__).resolve().parents[2]
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    rom = args.rom.resolve()
    wb = args.workbench.resolve()
    binary = root / 'build' / 'Q4ArgProbe'
    if not binary.exists():
        raise SystemExit('BLOCKED: run ci/qualification/build-q4-arg-probe.sh first')

    data = rom.read_bytes()
    if data.startswith(b'AMIROMTYPE1'):
        key = (rom.parent / 'rom.key').read_bytes()
        data = bytes(v ^ key[i % len(key)] for i, v in enumerate(data[11:]))
    if hashlib.sha1(data).hexdigest() != '11f9e62cf299f72184835b7b2a70a16333fc0d88':
        raise SystemExit('BLOCKED: verified Kickstart 1.2 rev 33.180 ROM not found')

    xdf = shutil.which('xdftool') or str(Path.home() / '.local/bin/xdftool')
    startup = command(xdf, wb, 'type', 's/startup-sequence')
    if sha256(wb) != '1035a9a317fbbf0056848a25397f245967d7a8f1bc5079b02a018f410899bdf0' or b'Workbench 1.2  V33.56' not in startup:
        raise SystemExit('BLOCKED: matching Workbench/AmigaDOS 1.2 media not found')

    private = Path(tempfile.mkdtemp(prefix='amiinternals-q4-argprobe-', dir='/tmp'))
    disk = private / 'workbench.adf'
    host_evidence = private / 'evidence'
    host_evidence.mkdir()
    shutil.copyfile(wb, disk)
    command(xdf, disk, 'makedir', 'Q4')
    command(xdf, disk, 'write', binary, 'Q4/Q4ArgProbe')

    # Runtime evidence is written to a host-directory drive (Q4E:) rather than
    # back into the boot floppy.  This removes ADF cache/flush ambiguity: each
    # marker becomes visible to the host as soon as AmigaDOS closes the file.
    sequence = out / 'startup-sequence'
    sequence.write_text(
        'FailAt 1\n'
        'Echo "AmigaOS 1.2 Q4 argument startup probe"\n'
        'Echo >Q4E:pre.txt "PRE"\n'
        'Echo "Q4ArgProbe stage 1: direct console"\n'
        'SYS:Q4/Q4ArgProbe Alpha "Beta Gamma"\n'
        'Echo >Q4E:returned1.txt "RETURNED1"\n'
        'Echo "Q4ArgProbe stage 2: redirected"\n'
        'SYS:Q4/Q4ArgProbe Alpha "Beta Gamma" >Q4E:output.txt\n'
        'Echo >Q4E:returned2.txt "RETURNED2"\n'
        'Type Q4E:output.txt\n'
        'Echo "Q4 argument startup probe returned normally"\n'
    )
    command(xdf, disk, 'delete', 's/startup-sequence')
    command(xdf, disk, 'write', sequence, 's/startup-sequence')

    # Prove before booting that the exact staged Startup-Sequence is present on
    # the private test disk.  Keep the read-back in the qualification evidence.
    readback = command(xdf, disk, 'type', 's/startup-sequence')
    (out / 'startup-sequence-readback').write_bytes(readback)
    expected_sequence = sequence.read_bytes()
    if readback.replace(b'\r\n', b'\n').replace(b'\r', b'\n') != expected_sequence.replace(b'\r\n', b'\n').replace(b'\r', b'\n'):
        raise SystemExit('BLOCKED: staged Startup-Sequence read-back differs from requested probe')

    config = out / 'session.fs-uae'
    config.write_text(
        '[fs-uae]\n'
        'amiga_model = A500\n'
        'cpu = 68000\n'
        'fpu = 0\n'
        'jit_compiler = 0\n'
        'cpu_speed = real\n'
        'chip_memory = 512\n'
        'slow_memory = 0\n'
        'fast_memory = 0\n'
        'chipset = OCS\n'
        'ntsc_mode = 0\n'
        f'kickstart_file = {rom}\n'
        f'kickstarts_dir = {rom.parent}\n'
        f'floppy_drive_0 = {disk}\n'
        'writable_floppy_images = 1\n'
        f'hard_drive_0 = {host_evidence}\n'
        'hard_drive_0_label = Q4E\n'
        f'base_dir = {private}\n'
        f'logs_dir = {out / "logs"}\n'
        'fullscreen = 0\n'
        'window_width = 800\n'
        'window_height = 600\n'
        'automatic_input_grab = 0\n'
    )

    evidence = {
        'commit': command('git', '-C', root, 'rev-parse', 'HEAD').decode().strip(),
        'worktree': command('git', '-C', root, 'status', '--short').decode(),
        'fs_uae_version': command('fs-uae', '--version').decode().strip(),
        'kickstart': '1.2 33.180',
        'rom_sha256': sha256(rom),
        'workbench': '1.2 V33.56',
        'workbench_sha256': sha256(wb),
        'binary_sha256': sha256(binary),
        'invocation': 'SYS:Q4/Q4ArgProbe Alpha "Beta Gamma"',
        'runtime_seconds': args.seconds,
        'evidence_volume': 'Q4E:',
        'startup_sequence_readback_sha256': sha256(out / 'startup-sequence-readback'),
        'stages': ['pre.txt', 'returned1.txt', 'output.txt', 'returned2.txt'],
    }
    (out / 'metadata.json').write_text(json.dumps(evidence, indent=2) + '\n')

    with (out / 'fs-uae.log').open('wb') as log:
        proc = subprocess.Popen(['fs-uae', str(config)], stdout=log, stderr=subprocess.STDOUT)
        try:
            deadline = time.time() + args.seconds
            # Stop early after a complete run; otherwise retain the full timeout
            # for a hung stage.  The evidence directory is host-visible.
            while time.time() < deadline:
                if (host_evidence / 'returned2.txt').exists():
                    time.sleep(1)
                    break
                time.sleep(1)
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()

    stage_names = ('pre.txt', 'returned1.txt', 'output.txt', 'returned2.txt')
    for name in stage_names:
        source = host_evidence / name
        if source.exists():
            shutil.copyfile(source, out / name)

    stages = {name: (out / name).exists() for name in stage_names}
    evidence['stage_results'] = stages
    (out / 'metadata.json').write_text(json.dumps(evidence, indent=2) + '\n')

    if not stages['pre.txt']:
        verdict = 'FAIL: Startup-Sequence did not create the host-visible pre marker'
    elif not stages['returned1.txt']:
        verdict = 'FAIL: Q4ArgProbe direct invocation did not return; failure is inside program/startup, before redirection is relevant'
    elif not stages['output.txt']:
        verdict = 'FAIL: direct invocation returned but redirected invocation produced no output'
    elif not stages['returned2.txt']:
        verdict = 'FAIL: redirected invocation produced output but did not return normally'
    else:
        text = (out / 'output.txt').read_text(errors='replace')
        expected = [
            'Q4ArgProbe 0.1\n',
            'argc: 3\n',
            'argv[0]: AmiInternals\n',
            'argv[1]: Alpha\n',
            'argv[2]: Beta Gamma\n',
        ]
        missing = [item.strip() for item in expected if item not in text]
        if missing:
            verdict = 'FAIL: argument startup output mismatch: ' + ', '.join(missing)
        else:
            verdict = 'PASS: start_cli_args on real Kickstart 1.2 + Workbench/AmigaDOS 1.2'

    (out / 'result.txt').write_text(verdict + '\n')
    print(json.dumps(stages, indent=2))
    if stages['output.txt']:
        print((out / 'output.txt').read_text(errors='replace'), end='')
    print(verdict)
    if not verdict.startswith('PASS:'):
        raise SystemExit(verdict)


if __name__ == '__main__':
    main()
