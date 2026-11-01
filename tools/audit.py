#!/usr/bin/env python3
"""Check distributable paths, likely credentials, and source integrity without printing secrets."""
from pathlib import Path
import hashlib,json,re,sys
ROOT=Path(__file__).resolve().parents[1]
PATTERNS={
 'Google API key':rb'AIza[0-9A-Za-z_-]{30,}',
 'GitHub token':rb'gh[pousr]_[0-9A-Za-z]{30,}',
 'Private key':rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
 'Bearer credential':rb'(?i)bearer\s+[a-zA-Z0-9_.-]{30,}',
 'Credential assignment':rb'''(?im)^\s*(?:export\s+)?(?:GOOGLE_API_KEY|GEMINI_API_KEY|NVIDIA_API_KEY|OPENWEATHER_KEY|WAKATIME_API_KEY)\s*=\s*["']?[a-zA-Z0-9_-]{20,}''',
 'Personal home':rb'/home/(?:wizrizz|ricky)(?:/|\b)',
}
def sources():return sorted(p for folder in ['payload','src'] for p in (ROOT/folder).rglob('*') if p.is_file())
def manifest():return {str(p.relative_to(ROOT)):{'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'mode':oct(p.stat().st_mode&0o777)} for p in sources()}
def audit(check_manifest=True):
 problems=[]
 for p in sources():
  rel=p.relative_to(ROOT);raw=p.read_bytes()
  if p.is_symlink():problems.append(str(rel)+': payload symlink')
  if any(x in {'.git','.env','__pycache__','history.jsonl','credentials.json','env'} for x in rel.parts):problems.append(str(rel)+': private/runtime path')
  if p.suffix.lower() in {'.pem','.key','.pyc','.so'}:problems.append(str(rel)+': prohibited artifact')
  for name,pattern in PATTERNS.items():
   if re.search(pattern,raw):problems.append(str(rel)+': '+name)
 if check_manifest:
  try:
   if json.loads((ROOT/'manifest.json').read_text())!=manifest():problems.append('manifest.json: source hashes or file set differ')
  except (OSError,ValueError):problems.append('manifest.json: missing or invalid')
 return problems
if __name__=='__main__':
 if '--write-manifest' in sys.argv:
  errors=audit(False)
  if errors:print('\n'.join(errors));sys.exit(1)
  (ROOT/'manifest.json').write_text(json.dumps(manifest(),indent=2)+'\n')
 errors=audit()
 if errors:print('\n'.join(errors));sys.exit(1)
 print('PASS:',len(sources()),'source/assets checked; no configured secret patterns found; manifest matches.')
 print('Pattern scanning is not proof that every possible secret or third-party licence has been identified.')
