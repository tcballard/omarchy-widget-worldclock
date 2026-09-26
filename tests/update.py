"""Verify staged package updates delegate to Core without rewriting user data."""
import json, os, subprocess, tempfile
from pathlib import Path
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
 home=Path(directory)
 core=home/'.config/omarchy/plugins/io.github.tcballard.widget-core/bin/omarchy-widget'
 core.parent.mkdir(parents=True)
 core.write_text('''#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
with open(Path(os.environ['HOME'])/'calls','a') as f:f.write(json.dumps(sys.argv[1:])+'\\n')
if sys.argv[1] in ['validate','update','install']:
 p=Path(sys.argv[2]);m=json.loads((p/'widget.json').read_text())
 assert m['coreApi']==3 and (p/m['settingsEntryPoint']).is_file()
 assert (p/'scripts/times').is_file()
 assert not (p/'test-results').exists() and not (p/'.git').exists()
if os.environ.get('FAIL_VALIDATE') and sys.argv[1]=='validate':sys.exit(1)
''');core.chmod(0o755)
 state=home/'state.json';saved='{"cities":["Europe/Paris"],"displayMode":"analogue","x":73,"enabled":false}';state.write_text(saved)
 env=dict(os.environ,HOME=str(home))
 for args,expected in [([],['validate','install','add']),(['--update'],['validate','update'])]:
  log=home/'calls';log.unlink(missing_ok=True)
  subprocess.run(['bash',str(root/'install-local'),*args],env=env,check=True)
  calls=[json.loads(line) for line in log.read_text().splitlines()]
  assert [c[0] for c in calls]==expected
  assert not Path(calls[0][1]).exists(), 'Staging directory must be removed'
  assert state.read_text()==saved
 (home/'calls').unlink()
 result=subprocess.run(['bash',str(root/'install-local'),'--update'],env=dict(env,FAIL_VALIDATE='1'))
 assert result.returncode!=0
 assert len((home/'calls').read_text().splitlines())==1
 assert state.read_text()==saved
print('PASS: API 3 staged install/update, no direct state mutation, validation failure stops update, stage cleanup')
