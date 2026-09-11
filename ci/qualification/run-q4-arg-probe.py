#!/usr/bin/env python3
"""A/B isolate AmiInternals argument startup on genuine AmigaOS 1.2 media.

The runtime is deliberately split into persistent phases so evidence can still be
collected when an outer command runner kills the process that launched FS-UAE.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import time


def command(*args):
    return subprocess.check_output([str(a) for a in args], stderr=subprocess.STDOUT)


def sha256(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extract(xdf, disk, guest, host):
    try:
        if host.exists():
            host.unlink()
        command(xdf, disk, 'read', guest, host)
        return True
    except subprocess.CalledProcessError:
        return False


def normalize(data):
    return data.replace(b'\r\n', b'\n').replace(b'\r', b'\n')


def load_metadata(out):
    path = out / 'metadata.json'
    if not path.exists():
        raise SystemExit('BLOCKED: no prepared probe; run --phase prepare first')
    return json.loads(path.read_text())


def save_metadata(out, evidence):
    (out / 'metadata.json').write_text(json.dumps(evidence, indent=2) + '\n')


def prepare(args, root, out, rom, wb):
    if out.exists():
        if any(out.iterdir()):
            raise SystemExit('BLOCKED: output directory already exists and is not empty: ' + str(out))
    else:
        out.mkdir(parents=True)

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

    runtime = out / 'runtime'
    runtime.mkdir()
    disk = runtime / 'workbench.adf'
    shutil.copyfile(wb, disk)
    command(xdf, disk, 'makedir', 'Q4')
    command(xdf, disk, 'write', control, 'Q4/Q4Control')
    command(xdf, disk, 'write', probe, 'Q4/Q4ArgProbe')

    for binary, guest in ((control, 'Q4/Q4Control'), (probe, 'Q4/Q4ArgProbe')):
        copied = runtime / (binary.name + '.readback')
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
    if normalize(readback) != normalize(sequence.read_bytes()):
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
        f'base_dir = {runtime}\n'
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
        'runtime_disk': str(disk),
        'phase': 'PREPARED',
    }
    save_metadata(out, evidence)
    (out / 'result.txt').write_text('PREPARED: Q4 startup A/B probe\n')
    print('PREPARED:', out)


def launch(out):
    evidence = load_metadata(out)
    config = out / 'session.fs-uae'
    disk = out / 'runtime' / 'workbench.adf'
    if not config.exists() or not disk.exists():
        raise SystemExit('BLOCKED: prepared runtime files are missing')

    pidfile = out / 'fs-uae.pid'
    if pidfile.exists():
        try:
            old_pid = int(pidfile.read_text().strip())
            os.kill(old_pid, 0)
            raise SystemExit('BLOCKED: FS-UAE appears to be already running with pid ' + str(old_pid))
        except ProcessLookupError:
            pidfile.unlink()

    log = (out / 'fs-uae.log').open('ab')
    proc = subprocess.Popen(
        ['fs-uae', str(config)],
        stdout=log,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    log.close()
    pidfile.write_text(str(proc.pid) + '\n')
    evidence['phase'] = 'LAUNCHED'
    evidence['fs_uae_pid'] = proc.pid
    evidence['launched_at_unix'] = time.time()
    save_metadata(out, evidence)
    (out / 'result.txt').write_text('LAUNCHED: FS-UAE pid ' + str(proc.pid) + '; collect after guest run\n')
    print('LAUNCHED: FS-UAE pid', proc.pid)
    print('The launcher has returned; runtime evidence remains on', disk)


def stop(out):
    evidence = load_metadata(out)
    pidfile = out / 'fs-uae.pid'
    if not pidfile.exists():
        print('STOP: no pid file; nothing to stop')
        return
    pid = int(pidfile.read_text().strip())
    try:
        os.killpg(pid, signal.SIGTERM)
        print('STOP: sent SIGTERM to FS-UAE process group', pid)
        deadline = time.time() + 10
        while time.time() < deadline:
            try:
                os.kill(pid, 0)
            except ProcessLookupError:
                break
            time.sleep(0.25)
        else:
            try:
                os.killpg(pid, signal.SIGKILL)
                print('STOP: sent SIGKILL after 10s grace period')
            except ProcessLookupError:
                pass
    except ProcessLookupError:
        print('STOP: FS-UAE was already gone')
    evidence['phase'] = 'STOPPED'
    evidence['stopped_at_unix'] = time.time()
    save_metadata(out, evidence)
    pidfile.unlink(missing_ok=True)


def collect(out):
    evidence = load_metadata(out)
    disk = out / 'runtime' / 'workbench.adf'
    if not disk.exists():
        raise SystemExit('BLOCKED: persistent runtime disk is missing')
    xdf = shutil.which('xdftool') or str(Path.home() / '.local/bin/xdftool')

    names = ('pre.txt', 'control.txt', 'control-returned.txt', 'arg.txt', 'arg-returned.txt')
    found = {}
    for name in names:
        found[name] = extract(xdf, disk, 'Q4/' + name, out / name)
        print(f'Q4 A/B: {name}: ' + ('FOUND' if found[name] else 'missing'), flush=True)

    evidence['files'] = found
    evidence['phase'] = 'COLLECTED'
    save_metadata(out, evidence)

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


def main():
    p = argparse.ArgumentParser(__doc__)
    p.add_argument('--phase', choices=('prepare', 'launch', 'stop', 'collect'), required=True)
    p.add_argument('--rom', type=Path)
    p.add_argument('--workbench', type=Path)
    p.add_argument('--out', type=Path, required=True)
    args = p.parse_args()

    root = Path(__file__).resolve().parents[2]
    out = args.out.resolve()

    if args.phase == 'prepare':
        if args.rom is None or args.workbench is None:
            raise SystemExit('BLOCKED: --phase prepare requires --rom and --workbench')
        prepare(args, root, out, args.rom.resolve(), args.workbench.resolve())
    elif args.phase == 'launch':
        launch(out)
    elif args.phase == 'stop':
        stop(out)
    else:
        collect(out)


if __name__ == '__main__':
    main()
