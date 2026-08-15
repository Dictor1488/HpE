# -*- coding: utf-8 -*-
from __future__ import print_function

import json
import os
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PYTHON_ROOT = ROOT / 'python'
AS3_BIN = ROOT / 'as3' / 'bin'
BUILD_DIR = ROOT / 'build'
TEMP_DIR = ROOT / 'temp'


def load_config():
    with (ROOT / 'build.json').open('r', encoding='utf-8') as fh:
        return json.load(fh)


def compile_python(python2):
    if not python2:
        raise RuntimeError('PYTHON2_EXE is not configured')
    python2 = Path(python2)
    if not python2.is_file():
        raise RuntimeError('Python 2.7 executable not found: %s' % python2)

    compiled = []
    for source in PYTHON_ROOT.rglob('*.py'):
        subprocess.check_call([str(python2), '-m', 'py_compile', str(source)])
        pyc = source.with_suffix('.pyc')
        if not pyc.is_file():
            raise RuntimeError('py_compile did not create %s' % pyc)
        compiled.append((source, pyc))
    return compiled


def clean_dir(path):
    if path.exists():
        shutil.rmtree(str(path))
    path.mkdir(parents=True)


def copy_tree(src, dst):
    src = Path(src)
    dst = Path(dst)
    if not src.exists():
        return
    for path in src.rglob('*'):
        relative = path.relative_to(src)
        target = dst / relative
        if path.is_dir():
            target.mkdir(parents=True, exist_ok=True)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(str(path), str(target))


def make_meta(info):
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<root>\n'
            '    <id>{id}</id>\n'
            '    <version>{version}</version>\n'
            '    <name>{name}</name>\n'
            '    <description>{description}</description>\n'
            '</root>\n').format(**info)


def zip_folder(source, destination):
    # WoT's .wotmod loader expects entries stored without DEFLATE compression.
    with zipfile.ZipFile(str(destination), 'w', zipfile.ZIP_STORED) as archive:
        for path in Path(source).rglob('*'):
            if path.is_file():
                archive.write(str(path), str(path.relative_to(source)).replace('\\', '/'))


def main():
    config = load_config()
    info = config['info']
    python2 = os.environ.get('PYTHON2_EXE') or config.get('python2')

    clean_dir(TEMP_DIR)
    clean_dir(BUILD_DIR)

    compiled = compile_python(python2)

    res = TEMP_DIR / 'res'
    res.mkdir(parents=True)

    resources = ROOT / 'resources' / 'in'
    copy_tree(resources, res)

    flash_dst = res / 'gui' / 'flash'
    flash_dst.mkdir(parents=True, exist_ok=True)
    swf_files = list(AS3_BIN.glob('*.swf'))
    if not swf_files:
        raise RuntimeError('No compiled SWF found in as3/bin')
    for swf in swf_files:
        shutil.copy2(str(swf), str(flash_dst / swf.name))

    scripts_dst = res / 'scripts' / 'client'
    for source, pyc in compiled:
        relative = source.relative_to(PYTHON_ROOT).with_suffix('.pyc')
        target = scripts_dst / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(str(pyc), str(target))

    (TEMP_DIR / 'meta.xml').write_text(make_meta(info), encoding='utf-8')

    package = BUILD_DIR / ('%s_%s.wotmod' % (info['id'], info['version']))
    zip_folder(TEMP_DIR, package)
    print('Created:', package)

    for _, pyc in compiled:
        try:
            pyc.unlink()
        except OSError:
            pass
    shutil.rmtree(str(TEMP_DIR), ignore_errors=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
