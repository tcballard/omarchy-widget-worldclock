"""Exercise installer replacement with a stubbed Core and shell, in private dirs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    home = Path(directory)
    core = home / '.config/omarchy/plugins/io.github.tcballard.widget-core/bin/omarchy-widget'
    core.parent.mkdir(parents=True)
    core.write_text('#!/bin/bash\nexit 0\n')
    core.chmod(0o755)
    commands = home / 'commands'
    commands.mkdir()
    shell = commands / 'omarchy-shell'
    shell.write_text('#!/bin/bash\nexit 0\n')
    shell.chmod(0o755)
    data = home / '.local/share/omarchy/widgets'
    old = data / 'packages/io.github.tcballard.worldclock'
    old.mkdir(parents=True)
    (old / 'old-marker').write_text('old snapshot')
    state = home / '.local/state/omarchy/widgets/layout.json'
    state.parent.mkdir(parents=True)
    saved = '{"cities":["Europe/Paris"],"x":73,"enabled":false}'
    state.write_text(saved)
    env = dict(os.environ, HOME=str(home), PATH=str(commands)+os.pathsep+os.environ['PATH'])
    env.pop('XDG_DATA_HOME', None)
    result = subprocess.run(['bash', str(root / 'install-local'), '--update'], env=env, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    assert state.read_text() == saved
    assert (old / 'CityEditor.qml').is_file()
    assert len(list(data.glob('.worldclock-backup.*/package/old-marker'))) == 1
    assert not (data / '.operation-lock').exists()
    (data / '.operation-lock').mkdir()
    result = subprocess.run(['bash', str(root / 'install-local'), '--update'], env=env, capture_output=True, text=True)
    assert result.returncode != 0
    assert state.read_text() == saved
print('PASS: update retains settings/placement and backup; active lock refuses replacement')
