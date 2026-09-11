#!/usr/bin/env python3
"""Local, visible AmigaOS 1.2 Q4 qualification. Never fetches system media."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

TOOLS = ['DF', 'DU', 'Find']


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

    if tool == 'DF':
        assert 'BlockSize Total Used Free Name\n' in text
        body = text.split('BlockSize Total Used Free Name\n', 1)[1]
        rows = [r for r in body.splitlines() if r and not r.startswith('Warning:')]
        assert rows, 'No mounted volumes listed'
        for row in rows:
            m = re.fullmatch(r'(\d+|\?) (\d+|\?) (\d+|\?) (\d+|\?) (.+)', row)
            assert m, row
            assert all(32 <= ord(c) < 127 for c in m.group(5)), row
            if m.group(2) != '?' and m.group(3) != '?' and m.group(4) != '?':
                total = int(m.group(2))
                used = int(m.group(3))
                free = int(m.group(4))
                assert used <= total, row
                assert free == total - used, row
    elif tool == 'DU':
        assert 'Bytes Files Dirs Errors Path\n' in text
        body = text.split('Bytes Files Dirs Errors Path\n', 1)[1]
        rows = [r for r in body.splitlines() if r]
        assert len(rows) == 1, rows
        m = re.fullmatch(r'(\d+) (\d+) (\d+) (\d+) (.+)', rows[0])
        assert m, rows[0]
        assert int(m.group(1)) > 0, rows[0]
        assert int(m.group(2)) >= 2, rows[0]
        assert int(m.group(3)) >= 2, rows[0]
        assert int(m.group(4)) == 0, rows[0]
        assert m.group(5).lower() == 'sys:q4/test', rows[0]
    else:
        assert 'SYS:Q4/Test/NeedleFile.txt' in text or 'sys:q4/test/needlefile.txt' in text.lower()
        mm = re.search(r'\nMatches: (\d+)\nErrors: (\d+)\n', text)
        assert mm, text
        assert int(mm.group(1)) >= 1, text
        assert int(mm.group(2)) == 0, text

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
        (args.out / 'result.txt').write_text('Q4: PASS — real Kickstart 1.2 + Workbench/AmigaDOS 1.2\n')
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

    private = Path(tempfile.mkdtemp(prefix='amiinternals-q4-', dir='/tmp'))
    disk = private / 'workbench.adf'
    shutil.copyfile(wb, disk)
    command(xdf, disk, 'makedir', 'Q4')
    command(xdf, disk, 'makedir', 'Q4/Test')
    command(xdf, disk, 'makedir', 'Q4/Test/Sub')

    alpha = private / 'Alpha.txt'
    needle = private / 'NeedleFile.txt'
    nested = private / 'Nested.txt'
    alpha.write_text('alpha q4 fixture\n')
    needle.write_text('needle q4 fixture\n')
    nested.write_text('nested q4 fixture\n')
    command(xdf, disk, 'write', alpha, 'Q4/Test/Alpha.txt')
    command(xdf, disk, 'write', needle, 'Q4/Test/NeedleFile.txt')
    command(xdf, disk, 'write', nested, 'Q4/Test/Sub/Nested.txt')

    binary = root / 'build' / args.tool
    if not binary.exists():
        raise SystemExit('BLOCKED: missing Q4 binary; run ci/qualification/build-q4.sh first')
    command(xdf, disk, 'write', binary, 'Q4/' + args.tool)
    extracted = private / args.tool
    command(xdf, disk, 'read', 'Q4/' + args.tool, extracted)
    assert sha(binary) == sha(extracted), 'Guest binary differs from host binary'

    status = private / 'Q4Status'
    command('m68k-amigaos-gcc', '-I'+str(root/'include'), '-Os', '-Wall', '-Wextra',
        '-Werror', '-m68000', '-msoft-float', '-noixemul', '-nostdlib',
        '-o', status, root/'src/common/start_cli.S', root/'src/common/start_cli.c',
        root/'src/common/output.c', root/'ci/qualification/status.c', '-lgcc', '-lnix13')
    command(xdf, disk, 'write', status, 'Q4/Q4Status')

    if args.tool == 'DF':
        invocation = 'SYS:Q4/DF'
    elif args.tool == 'DU':
        invocation = 'SYS:Q4/DU SYS:Q4/Test'
    else:
        invocation = 'SYS:Q4/Find Needle SYS:Q4/Test'

    sequence = out / 'startup-sequence'
    sequence.write_text('FailAt 1\n'
        'Echo "AmigaOS 1.2 Q4: ' + args.tool + '"\n'
        + invocation + ' >SYS:Q4/output.txt\n'
        'SYS:Q4/Q4Status >SYS:Q4/status.txt\n'
        'Echo >SYS:Q4/returned.txt "RETURNED BELOW FAILAT 1"\n'
        'Type SYS:Q4/output.txt\n'
        'Type SYS:Q4/status.txt\n'
        'Echo "Q4 command returned normally"\n')
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
        tool=args.tool, invocation=invocation, private_media=str(private),
        fs_uae_version=command('fs-uae', '--version').decode().strip())
    evidence['working_tree_status'] = command('git', '-C', root, 'status', '--short').decode()
    source_files = ['src/common/start_cli_args.S', 'src/common/start_cli_args.c',
        'src/common/compat.c', 'src/common/output.c', 'include/ai_compat.h',
        'src/'+args.tool.lower()+'/main.c', 'ci/qualification/status.c',
        'ci/qualification/build-q4.sh', 'ci/qualification/run-q4.py']
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
            command(xdf, disk, 'read', 'Q4/' + name, out / name)
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
