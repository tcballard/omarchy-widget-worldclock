"""The opt-in renderer only updates an existing clock after validation."""
import json
import os
import subprocess
import tempfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    home = Path(directory)
    core = home / '.config/omarchy/plugins/io.github.tcballard.widget-core/bin/omarchy-widget'
    core.parent.mkdir(parents=True)
    core.write_text('''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
with open(Path(os.environ['HOME'])/'calls', 'a') as log:
 log.write(json.dumps(sys.argv[1:]) + '\\n')
if sys.argv[1] in ('validate', 'update'):
 p=Path(sys.argv[2]); manifest=json.loads((p/'widget.json').read_text())
 assert manifest['coreApi']==3 and manifest['renderer']=='declarative'
 assert 'declarative-v1' in manifest['requires']
 assert sorted(file.name for file in p.iterdir())==['LICENSE', 'widget.json']
if os.environ.get('FAIL_VALIDATE') and sys.argv[1]=='validate':
 sys.exit(1)
''')
    core.chmod(0o755)
    state = home / 'saved-settings'
    state.write_text('{"cities":["Europe/Paris"],"style":"solar"}')
    env = dict(os.environ, HOME=str(home))
    command = ['bash', str(root / 'experimental/declarative/install-local'), '--update']
    subprocess.run(command, env=env, check=True)
    calls = [json.loads(line) for line in (home / 'calls').read_text().splitlines()]
    assert [call[0] for call in calls] == ['validate', 'update']
    assert not Path(calls[0][1]).exists(), 'Staged package must be removed'
    assert state.read_text() == '{"cities":["Europe/Paris"],"style":"solar"}'
    (home / 'calls').unlink()
    result = subprocess.run(command, env=dict(env, FAIL_VALIDATE='1'))
    assert result.returncode != 0
    assert len((home / 'calls').read_text().splitlines()) == 1
    assert state.read_text() == '{"cities":["Europe/Paris"],"style":"solar"}'
    assert subprocess.run(command[:-1], env=env, capture_output=True).returncode != 0
print('PASS: opt-in staged update, validation gate, cleanup and settings preservation')
