#!/usr/bin/env python3
"""Local, visible AmigaOS 1.2 Q2 qualification. Never fetches system media."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
import re

TOOLS = ['Ports', 'Libs', 'Devices']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def command(*args):
    return subprocess.check_output([str(a) for a in args], stderr=subprocess.STDOUT)


def validate(out, tool):
    log = (out / 'logs/fs-uae.log.txt').read_text(errors='replace')
    config = (out / 'logs/debug.uae').read_text()
    assert "Known ROM 'KS ROM v1.2 (A500,A1000,A2000)' loaded" in log
    assert 'CPU=68000, FPU=0, MMU=0, JIT=0.' in log
    for setting in ['chipmem_size=1', 'fastmem_size=0', 'bogomem_size=0',
                    'chipset=ocs', 'cpu_speed=real', 'cachesize=0']:
        assert setting in config.splitlines(), setting

    text = (out / 'output.txt').read_text()
    status = (out / 'status.txt').read_text()
    assert (out / 'returned.txt').exists(), 'No normal-return marker'
    assert 'Previous RC: 0\n' in status, status
    assert re.search(r'DOS: 33\.\d+\n', status), status
    assert tool + ' 0.1\n' in text
    assert 'AmiInternals - Ploos AS' in text

    if tool == 'Ports':
        assert 'Sig Name\n' in text
        body = text.split('Sig Name\n', 1)[1]
        rows = [r for r in body.splitlines() if r and not r.startswith('Warning:')]
        for row in rows:
            m = re.fullmatch(r'(\d+) (.+)', row)
            assert m, row
            assert 0 <= int(m.group(1)) <= 31, row
            assert all(32 <= ord(c) < 127 for c in m.group(2)), row
    else:
        assert 'Version Name\n' in text
        body = text.split('Version Name\n', 1)[1]
        rows = [r for r in body.splitlines() if r and not r.startswith('Warning:')]
        assert rows, 'No entries listed'
        for row in rows:
            m = re.fullmatch(r'(\d+)\.(\d+) (.+)', row)
            assert m, row
            assert 0 <= int(m.group(1)) <= 65535
            assert 0 <= int(m.group(2)) <= 65535
            assert all(32 <= ord(c) < 127 for c in m.group(3)), row
        names = [re.fullmatch(r'(\d+)\.(\d+) (.+)', r).group(3).lower() for r in rows]
        if tool == 'Libs':
            assert any('dos.library' in n or 'graphics.library' in n or 'intuition.library' in n for n in names), names
        else:
            assert any(n.endswith('.device') for n in names), names

    return 'PASS'


def screenshot(path):
    import ctypes as c
    from PIL import Image
    tree = command('xwininfo', '-root', '-tree').decode()
    windows = re.findall(r'(0x[0-9a-f]+) "FS-UAE[^\n]+\("fs-uae" "fs-uae"\) +([0-9]+)x([0-9]+)', tree)
    if len(windows) != 1:
        raise RuntimeError('Expected exactly one visible FS-UAE window')
    wid, width, height = windows[0]
    width, height = int(width), int(height)
    x = c.CDLL('libX11.so.6')
    composite = c.CDLL('libXcomposite.so.1')
    x.XOpenDisplay.restype = c.c_void_p
    display = x.XOpenDisplay(None)
    if not display:
        raise RuntimeError('Cannot open visible X display')
    composite.XCompositeNameWindowPixmap.argtypes = [c.c_void_p, c.c_ulong]
    composite.XCompositeNameWindowPixmap.restype = c.c_ulong
    x.XGetImage.argtypes = [c.c_void_p, c.c_ulong, c.c_int, c.c_int, c.c_uint, c.c_uint, c.c_ulong, c.c_int]
    x.XGetImage.restype = c.c_void_p
    x.XGetPixel.argtypes = [c.c_void_p, c.c_int, c.c_int]
    x.XGetPixel.restype = c.c_ulong
    x.XDestroyImage.argtypes = [c.c_void_p]
    x.XFreePixmap.argtypes = [c.c_void_p, c.c_ulong]
    x.XCloseDisplay.argtypes = [c.c_void_p]
    pixmap = composite.XCompositeNameWindowPixmap(display, int(wid, 16))
    im = x.XGetImage(display, pixmap, 0, 0, width, height, c.c_ulong(-1), 2)
    if not im:
        raise RuntimeError('Cannot capture emulator pixmap')
    rgb = bytearray()
    for y in range(height):
        for xx in range(width):
            pixel = x.XGetPixel(im, xx, y)
            rgb.extend(((pixel >> 16) & 255, (pixel >> 8) & 255, pixel & 255))
    Image.frombytes('RGB', (width, height), bytes(rgb)).save(path)
    x.XDestroyImage(im)
    x.XFreePixmap(display, pixmap)
    x.XCloseDisplay(display)


def main():
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument('--rom', type=Path, required=True)
    parser.add_argument('--workbench', type=Path, required=True)
    parser.add_argument('--tool', choices=TOOLS)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--seconds', type=int, default=65)
    args = parser.parse_args()

    if args.tool is None:
        for tool in TOOLS:
            subprocess.run([os.sys.executable, __file__, '--rom', str(args.rom),
                '--workbench', str(args.workbench), '--tool', tool,
                '--out', str(args.out / tool), '--seconds', str(args.seconds)], check=True)
        (args.out / 'result.txt').write_text('Q2: PASS — real Kickstart 1.2 + Workbench/AmigaDOS 1.2\n')
        return

    root = Path(__file__).resolve().parents[2]
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    rom = args.rom.resolve()
    wb = args.workbench.resolve()

    data = rom.read_bytes()
    if data.startswith(b'AMIROMTYPE1'):
        key = (rom.parent / 'rom.key').read_bytes()
        data = bytes(v ^ key[i % len(key)] for i, v in enumerate(data[11:]))
    if hashlib.sha1(data).hexdigest() != '11f9e62cf299f72184835b7b2a70a16333fc0d88':
        raise SystemExit('BLOCKED: verified KS1.2 33.180 ROM not found')
    del data

    xdf = shutil.which('xdftool') or str(Path.home() / '.local/bin/xdftool')
    startup = command(xdf, wb, 'type', 's/startup-sequence')
    if (sha(wb) != '1035a9a317fbbf0056848a25397f245967d7a8f1bc5079b02a018f410899bdf0'
            or b'Workbench 1.2  V33.56' not in startup):
        raise SystemExit('BLOCKED: matching Workbench/AmigaDOS 1.2 environment not found')

    private = Path(tempfile.mkdtemp(prefix='amiinternals-q2-', dir='/tmp'))
    disk = private / 'workbench.adf'
    shutil.copyfile(wb, disk)
    command(xdf, disk, 'makedir', 'Q2')
    binary = root / 'build' / args.tool
    if not binary.exists():
        raise SystemExit('BLOCKED: missing Q2 binary; run ci/qualification/build-q2.sh first')
    command(xdf, disk, 'write', binary, 'Q2/' + args.tool)
    extracted = private / args.tool
    command(xdf, disk, 'read', 'Q2/' + args.tool, extracted)
    assert sha(binary) == sha(extracted), 'Guest binary differs from host binary'

    status = private / 'Q2Status'
    command('m68k-amigaos-gcc', '-I'+str(root/'include'), '-Os', '-Wall', '-Wextra',
        '-Werror', '-m68000', '-msoft-float', '-noixemul', '-nostdlib',
        '-o', status, root/'src/common/start_cli.S', root/'src/common/start_cli.c',
        root/'src/common/output.c', root/'ci/qualification/status.c', '-lgcc', '-lnix13')
    command(xdf, disk, 'write', status, 'Q2/Q2Status')

    sequence = out / 'startup-sequence'
    sequence.write_text('FailAt 1\n'
        'Echo "AmigaOS 1.2 Q2: ' + args.tool + '"\n'
        'SYS:Q2/' + args.tool + ' >SYS:Q2/output.txt\n'
        'SYS:Q2/Q2Status >SYS:Q2/status.txt\n'
        'Echo >SYS:Q2/returned.txt "RETURNED BELOW FAILAT 1"\n'
        'Type SYS:Q2/output.txt\n'
        'Type SYS:Q2/status.txt\n'
        'Echo "Q2 command returned normally"\n')
    command(xdf, disk, 'delete', 's/startup-sequence')
    command(xdf, disk, 'write', sequence, 's/startup-sequence')

    config = out / 'session.fs-uae'
    config.write_text('[fs-uae]\n'
        'amiga_model = A500\ncpu = 68000\nfpu = 0\njit_compiler = 0\n'
        'cpu_speed = real\nchip_memory = 512\nslow_memory = 0\nfast_memory = 0\n'
        'chipset = OCS\nntsc_mode = 0\n'
        f'kickstart_file = {rom}\nkickstarts_dir = {rom.parent}\n'
        f'floppy_drive_0 = {disk}\nwritable_floppy_images = 1\n'
        f'base_dir = {private}\nlogs_dir = {out / "logs"}\n'
        f'screenshots_dir = {out / "screenshots"}\n'
        'fullscreen = 0\nwindow_width = 800\nwindow_height = 600\n'
        'automatic_input_grab = 0\n')

    evidence = dict(commit=command('git', '-C', root, 'rev-parse', 'HEAD').decode().strip(),
        rom_path=str(rom), rom_size=rom.stat().st_size, rom_sha256=sha(rom),
        kickstart='1.2 33.180', workbench_path=str(wb), workbench_sha256=sha(wb),
        workbench='1.2 V33.56 (local Amiga Forever disk)', binary_sha256=sha(binary),
        tool=args.tool, private_media=str(private),
        fs_uae_version=command('fs-uae', '--version').decode().strip())
    evidence['working_tree_status'] = command('git', '-C', root, 'status', '--short').decode()
    source_files = ['src/common/start_cli.S', 'src/common/start_cli.c',
        'src/common/compat.c', 'src/common/output.c', 'include/ai_compat.h',
        'src/'+args.tool.lower()+'/main.c', 'ci/qualification/status.c',
        'ci/qualification/build-q2.sh', 'ci/qualification/run-q2.py']
    evidence['source_sha256'] = {name: sha(root/name) for name in source_files}
    (out / 'metadata.json').write_text(json.dumps(evidence, indent=2)+'\n')

    with (out / 'fs-uae.log').open('wb') as log:
        proc = subprocess.Popen(['fs-uae', str(config)], stdout=log, stderr=subprocess.STDOUT)
        try:
            time.sleep(args.seconds)
            try:
                screenshot(out / 'session.png')
            except (OSError, RuntimeError) as error:
                (out / 'screenshot-error.txt').write_text(str(error)+'\n')
        finally:
            proc.terminate()
            try:
                proc.wait(timeout=10)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait()

    for name in ['output.txt', 'returned.txt', 'status.txt']:
        try:
            command(xdf, disk, 'read', 'Q2/' + name, out / name)
        except subprocess.CalledProcessError:
            pass

    print(json.dumps(evidence, indent=2))
    print((out / 'output.txt').read_text() if (out / 'output.txt').exists() else 'NO CAPTURED OUTPUT')
    try:
        verdict = validate(out, args.tool)
    except (AssertionError, OSError) as error:
        (out / 'result.txt').write_text('FAIL: ' + str(error) + '\n')
        raise SystemExit('FAIL: qualification stopped at ' + args.tool)
    (out / 'result.txt').write_text(verdict+' — real Kickstart 1.2 + Workbench/AmigaDOS 1.2\n')


if __name__ == '__main__':
    main()
