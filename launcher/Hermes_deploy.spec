# -*- mode: python ; coding: utf-8 -*-
# PyInstaller spec — Hermes Launcher (Deploy Edition)
# Build: pyinstaller Hermes_deploy.spec

import sys
from pathlib import Path

PY_BASE = Path(sys.base_prefix)
TK_BINARIES = [
    (str(PY_BASE / 'DLLs' / '_tkinter.pyd'), '.'),
    (str(PY_BASE / 'DLLs' / 'tcl86t.dll'), '.'),
    (str(PY_BASE / 'DLLs' / 'tk86t.dll'), '.'),
]
TK_DATAS = [
    (str(PY_BASE / 'tcl' / 'tcl8.6'), '_tcl_data'),
    (str(PY_BASE / 'tcl' / 'tk8.6'), '_tk_data'),
    (str(PY_BASE / 'tcl' / 'tcl8'), 'tcl8'),
    ('icon.ico', '.'),
    ('app_icon.png', '.'),
]

a = Analysis(
    ['launcher_deploy.py'],
    pathex=[],
    binaries=TK_BINARIES,
    datas=TK_DATAS,
    hiddenimports=['tkinter', '_tkinter'],
    hookspath=['hooks'],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    a.binaries,
    a.datas,
    [],
    name='Hermes',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['icon.ico'],
)
