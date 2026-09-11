#!/usr/bin/env python3
"""A/B isolate AmiInternals argument startup on genuine AmigaOS 1.2 media."""
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


def extract(xdf, disk, guest, host):
    try:
        command(xdf, disk, 'read', guest, host)
        return True
    except subprocess.CalledProcessError:
        return False


def main():
    p = argparse.ArgumentParser(__doc__)
    p.add_argument('--rom', type=Path, required=True)
    p.add_argument('--workbench', type=Path, required=True)
    p.add_argument('--out', type=Path, required=True)
    # Q1-Q3 real-classic qualification uses 65 seconds successfully. Keep the
    # same proven window here so Python still has time to terminate FS-UAE,
    # extract floppy evidence, and write the verdict before an outer command
    # runner with a ~90 second budget can kill the whole harness.
    p.add_argument('--seconds', type=int, default=65)
    args = p.parse_args()

    root = Path(__file__).resolve().parents[2]
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    rom = args.rom.resolve()
    wb = args.workbench.resolve()
    control = root / 'build' / 'Q4Control'
    probe = root / 'build' / 'Q4ArgProbe'
    if not control.exists() or not probe.exists():
        raise SystemExit('BLOCKED: run ci/qualification/build-q4-arg-probe.sh first')

    data = rom.read_bytes()
    if data.startswith(b'AMIROMTYPE1'):
        key = (rom.parent / 'rom.key').read_bytes()
        data = bytes(v ^ key[i % len(key)] for i, v in enumerate(data[11:]))
    if hashlib.sha1(data).hexdigest() != '11f9e62cf299f72184835b7b2a70a16333fc0d88':
        raise SystemExit('BLOCKED: verified Kickstart 1.2 rev 33.180 ROM not found')

    xdf = shutil.which('xdftool') or str(Path.home() / '.local/bin/xdftool')
    original_startup = command(xdf, wb, 'type', 's/startup-sequence')
    if sha256(wb) != '1035a9a317fbbf0056848a25397f245967d7a8f1bc5079b02a018f410899bdf0' or b'Workbench 1.2  V33.56' not in original_startup:
        raise SystemExit('BLOCKED: matching Workbench/AmigaDOS 1.2 media not found')

    private = Path(tempfile.mkdtemp(prefix='amiinternals-q4-ab-', dir='/tmp'))
    disk = private / 'workbench.adf'
    shutil.copyfile(wb, disk)
    command(xdf, disk, 'makedir', 'Q4')
    command(xdf, disk, 'write', control, 'Q4/Q4Control')
    command(xdf, disk, 'write', probe, 'Q4/Q4ArgProbe')

    for binary, guest in ((control, 'Q4/Q4Control'), (probe, 'Q4/Q4ArgProbe')):
        copied = private / binary.name
        command(xdf, disk, 'read', guest, copied)
        if sha256(binary) != sha256(copied):
            raise SystemExit('BLOCKED: guest binary differs from host binary: ' + binary.name)

    sequence = out / 'startup-sequence'
    sequence.write_text(
        'FailAt 1\n'
        'Echo "AmigaOS 1.2 Q4 startup A/B probe"\n'
        'Echo >SYS:Q4/pre.txt "PRE"\n'
        'SYS:Q4/Q4Control >SYS:Q4/control.txt\n'
        'Echo >SYS:Q4/control-returned.txt "CONTROL_RETURNED"\n'
        'SYS:Q4/Q4ArgProbe Alpha "Beta Gamma" >SYS:Q4/arg.txt\n'
        'Echo >SYS:Q4/arg-returned.txt "ARG_RETURNED"\n'
        'Type SYS:Q4/control.txt\n'
        'Type SYS:Q4/arg.txt\n'
        'Echo "Q4 startup A/B probe returned normally"\n'
    )
    command(xdf, disk, 'delete', 's/startup-sequence')
    command(xdf, disk, 'write', sequence, 's/startup-sequence')
    readback = command(xdf, disk, 'type', 's/startup-sequence')
    (out / 'startup-sequence-readback').write_bytes(readback)
    if readback.replace(b'\r\n', b'\n').replace(b'\r', b'\n') != sequence.read_bytes().replace(b'\r\n', b'\n').replace(b'\r', b'\n'):
        raise SystemExit('BLOCKED: staged Startup-Sequence read-back differs')

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
        'control_sha256': sha256(control),
        'arg_probe_sha256': sha256(probe),
        'runtime_seconds': args.seconds,
        'private_media': str(private),
    }
    (out / 'metadata.json').write_text(json.dumps(evidence, indent=2) + '\n')
    # This is deliberately created before launching FS-UAE. If an outer runner
    # kills the Python process, the retained RUNNING verdict proves that no guest
    # conclusion was reached rather than mislabelling the run as a guest FAIL.
    (out / 'result.txt').write_text('RUNNING: Q4 startup A/B probe; no verdict yet\n')

    print(f'Q4 A/B: launching FS-UAE for {args.seconds}s', flush=True)
    with (out / 'fs-uae.log').open('wb') as log:
        proc = subprocess.Popen(['fs-uae', str(config)], stdout=log, stderr=subprocess.STDOUT)
        started = time.time()
        while time.time() - started < args.seconds:
            rc = proc.poll()
            if rc is not None:
                evidence['fs_uae_early_exit'] = rc
                print('Q4 A/B: FS-UAE exited early with rc', rc, flush=True)
                break
            time.sleep(1)
        if proc.poll() is None:
            print('Q4 A/B: runtime complete; terminating emulator', flush=True)
            proc.terminate()
            try:
                proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()
        evidence['fs_uae_exit_code'] = proc.returncode

    names = ('pre.txt', 'control.txt', 'control-returned.txt', 'arg.txt', 'arg-returned.txt')
    found = {}
    for name in names:
        found[name] = extract(xdf, disk, 'Q4/' + name, out / name)
        print(f'Q4 A/B: {name}: ' + ('FOUND' if found[name] else 'missing'), flush=True)

    evidence['files'] = found
    (out / 'metadata.json').write_text(json.dumps(evidence, indent=2) + '\n')

    if not found['pre.txt']:
        verdict = 'FAIL: Startup-Sequence did not reach the first Q4 marker'
    elif not found['control-returned.txt']:
        verdict = 'FAIL: known-good argument-free startup control did not return; harness/environment regression'
    elif not found['arg.txt'] and not found['arg-returned.txt']:
        verdict = 'FAIL: control passed but argument startup did not produce output or return; start_cli_args isolated'
    elif not found['arg-returned.txt']:
        verdict = 'FAIL: argument startup produced output but did not return normally'
    else:
        text = (out / 'arg.txt').read_text(errors='replace')
        expected = ('Q4ArgProbe 0.1', 'argc: 3', 'argv[0]: AmiInternals', 'argv[1]: Alpha', 'argv[2]: Beta Gamma')
        missing = [item for item in expected if item not in text]
        verdict = ('FAIL: argument startup output mismatch: ' + ', '.join(missing)) if missing else 'PASS: start_cli_args on real Kickstart 1.2 + Workbench/AmigaDOS 1.2'

    (out / 'result.txt').write_text(verdict + '\n')
    print(verdict, flush=True)
    if not verdict.startswith('PASS:'):
        raise SystemExit(verdict)


if __name__ == '__main__':
    main()
