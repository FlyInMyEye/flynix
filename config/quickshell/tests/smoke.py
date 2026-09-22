#!/usr/bin/env python3
"""Run the actual UI components and Qt mouse/keyboard tests offscreen.

No production QML is rewritten, no compositor is attached and no session lock is
acquired. Wayland protocol and physical-output checks remain separate.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--qs', default='qs')
parser.add_argument('--artifacts', default='/tmp/island-smoke-artifacts')
parser.add_argument('--test', default='', help='Run one named QML test function')
args = parser.parse_args()
artifacts = Path(args.artifacts).resolve()
artifacts.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='island-tests-') as directory:
    runtime = Path(directory) / 'runtime'
    runtime.mkdir(mode=0o700)
    home = Path(directory) / 'home'
    for folder, suffix in [('Documents', 'pdf'), ('Downloads', 'png')]:
        target = home / folder
        target.mkdir(parents=True)
        (target / ('island-file-fixture.' + suffix)).write_bytes(b'fixture')
    env = dict(os.environ, QT_QPA_PLATFORM='offscreen', QT_QUICK_BACKEND='software',
               HOME=str(home),
               XDG_RUNTIME_DIR=str(runtime), XDG_CACHE_HOME=directory + '/cache',
               DBUS_SESSION_BUS_ADDRESS='unix:path=' + directory + '/no-session-bus',
               DBUS_SYSTEM_BUS_ADDRESS='unix:path=' + directory + '/no-system-bus',
               ISLAND_SMOKE_ARTIFACTS=str(artifacts))
    env['ISLAND_SMOKE_TEST'] = args.test
    env['ISLAND_TEST_WALLPAPER'] = (Path(__file__).resolve().parents[3] / 'wallpapers/ign_astronaut.png').as_uri()
    # Child processes must use the same Quickshell selected by --qs.
    qs_binary = Path(shutil.which(args.qs) or args.qs).resolve()
    env['PATH'] = str(qs_binary.parent) + os.pathsep + env.get('PATH', '')
    for name in ('WAYLAND_DISPLAY', 'HYPRLAND_INSTANCE_SIGNATURE'):
        env.pop(name, None)
    result = subprocess.run([args.qs, '-p', str(Path(__file__).resolve().parents[1] / 'test.qml')],
                            env=env, capture_output=True, text=True, timeout=90)
    output = result.stdout + result.stderr
    (artifacts / 'smoke.log').write_text(output)
    print(output)
    bad = ('Failed to load configuration', 'TypeError:', 'ReferenceError:', 'Binding loop',
           'Unable to assign', 'ASSERTION:', ' FAIL')
    if result.returncode != 0 or 'UI RESULT 0 failures' not in output or any(item in output for item in bad):
        raise SystemExit(f'UI tests failed (exit {result.returncode}); see ' + str(artifacts / 'smoke.log'))
    print('UI interaction tests passed. This does not certify Wayland session-lock behavior.')
