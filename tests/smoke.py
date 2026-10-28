from pathlib import Path
import tempfile,subprocess,os,json,shutil
import sys
repo=Path(__file__).resolve().parents[1]
platform=sys.argv[1] if len(sys.argv)>1 else 'linux'
assert platform in ('linux','macos')
installer='install-linux.sh' if platform=='linux' else 'install.sh'
uninstaller='uninstall-linux.sh' if platform=='linux' else 'uninstall.sh'
passed=[]
def run(home,script=installer,ok=True,package=repo,extra=None):
 env=dict(os.environ,CODEX_HOME=str(home));env.update(extra or {})
 r=subprocess.run(['bash',str(package/script)],env=env,capture_output=True,text=True)
 assert (r.returncode==0)==ok,(script,r.returncode,r.stdout,r.stderr)
with tempfile.TemporaryDirectory(prefix='von-release-test-') as td:
 b=Path(td);h=b/'space home';run(h);t=h/'pets/von';payload=(t/'spritesheet.webp').read_bytes();run(h)
 assert (t/'spritesheet.webp').read_bytes()==payload and json.loads((t/'pet.json').read_text())['id']=='von'
 passed+=['Fresh and repeat installation into a path containing spaces']
 o=h/'pets/other';o.mkdir();(o/'keep').write_text('keep');run(h,uninstaller);run(h,uninstaller);assert (o/'keep').exists()
 passed+=['Removal and repeated removal preserve other pets']
 h=b/'legacy';t=h/'pets/von-blink';t.mkdir(parents=True);shutil.copy2(repo/'spritesheet.webp',t/'spritesheet.webp')
 (t/'pet.json').write_text(json.dumps(dict(id='von-blink',displayName='Von',description='old',spritesheetPath='spritesheet.webp')))
 (t/'notes').write_text('keep');run(h);d=json.loads((t/'pet.json').read_text());assert d['id']=='von-blink' and d['description']=='Armed & Dangerous' and not (h/'pets/von').exists()
 passed+=['Legacy update preserves registered directory and ID without a duplicate']
 bins=b/'bin';bins.mkdir();w=bins/'mv';w.write_text('#!/bin/bash\ncase "$1" in */.von-stage.*) exit 73;; esac\nexec /bin/mv "$@"\n');w.chmod(0o755)
 old=(t/'pet.json').read_bytes();run(h,ok=False,extra={'PATH':str(bins)+':'+os.environ['PATH']});assert (t/'pet.json').read_bytes()==old and (t/'notes').exists();assert not list((h/'pets').glob('.von-*'))
 passed+=['Injected final-rename failure restores the original and releases the lock']
 run(h,uninstaller);assert (t/'notes').exists();passed+=['Extra files in the Von directory survive removal']
 h=b/'modified';run(h);f=h/'pets/von/pet.json';f.write_text(f.read_text()+' ');run(h,uninstaller,ok=False);assert f.exists();passed+=['Modified managed files cause safe refusal']
 bad=b/'bad package';shutil.copytree(repo,bad);(bad/'spritesheet.webp').write_bytes(b'bad');h=b/'untouched';run(h,ok=False,package=bad);assert not (h/'pets/von').exists();passed+=['Corrupt package rejected before mutation']
 h=b/'symlink';(h/'pets').mkdir(parents=True);(h/'pets/von').symlink_to(o,target_is_directory=True);run(h,ok=False);assert (o/'keep').exists();passed+=['Symlink targets rejected']
 h=b/'both';run(h);shutil.copytree(h/'pets/von',h/'pets/von-blink');f=h/'pets/von-blink/pet.json';d=json.loads(f.read_text());d['id']='von-blink';f.write_text(json.dumps(d));run(h,ok=False);passed+=['Duplicate current and legacy installations rejected']
print('\n'.join('PASS '+x for x in passed))
