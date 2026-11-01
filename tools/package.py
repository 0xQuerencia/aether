#!/usr/bin/env python3
"""Create a source release, excluding Git history, logs, caches and local build outputs."""
from pathlib import Path
import hashlib,subprocess,sys,tarfile
ROOT=Path(__file__).resolve().parents[1]
subprocess.run([sys.executable,str(ROOT/'tools/audit.py')],check=True)
OUT=ROOT/'dist';OUT.mkdir(exist_ok=True);dest=OUT/'aether-shell-source.tar.gz'
with tarfile.open(dest,'w:gz',compresslevel=9) as tar:
 for p in sorted(ROOT.rglob('*')):
  rel=p.relative_to(ROOT)
  if any(x in {'.git','build','dist','__pycache__'} for x in rel.parts) or p.suffix in {'.pyc','.log','.so'}:continue
  if p.is_symlink():raise SystemExit('Unexpected release symlink: '+str(rel))
  if p.is_file():tar.add(p,arcname='aether/'+str(rel),recursive=False)
(OUT/'SHA256SUMS').write_text(hashlib.sha256(dest.read_bytes()).hexdigest()+'  '+dest.name+'\n')
print(dest);print('Size:',dest.stat().st_size,'bytes')
