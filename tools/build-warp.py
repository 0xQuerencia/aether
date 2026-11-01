#!/usr/bin/env python3
"""Build only, against local Hyprland headers. No plugin is installed or loaded."""
from pathlib import Path
import argparse,hashlib,json,re,shlex,subprocess,tempfile,os
ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--output',type=Path,default=ROOT/'build/warp');args=p.parse_args()
flags=shlex.split(subprocess.check_output(['pkg-config','--cflags','hyprland'],text=True))
version=Path('/usr/include/hyprland/src/version.h')
headers=[Path(f[2:])/'src/version.h' for f in flags if f.startswith('-I')]+[version]
header=next((h for h in headers if h.is_file()),None)
if not header:raise SystemExit('Hyprland version.h is missing. Install the matching development headers first.')
m=re.search(r'#define\s+GIT_COMMIT_HASH\s+"([a-f0-9]{40})"',header.read_text())
if not m:raise SystemExit('Could not identify the exact Hyprland header commit; build stopped.')
args.output.mkdir(parents=True,exist_ok=True)
with tempfile.TemporaryDirectory(prefix='aether-warp-build-') as tmp:
 binary=Path(tmp)/'aether-warp.so'
 subprocess.run(['g++','-std=c++23','-O2','-shared','-fPIC',*flags,str(ROOT/'src/warp/warp.cpp'),'-o',str(binary)],check=True)
 data=binary.read_bytes();dest=args.output/'aether-warp.so';temp=dest.with_suffix('.new');temp.write_bytes(data);os.replace(temp,dest)
 (args.output/'build.json').write_text(json.dumps({'commit':m[1],'sha256':hashlib.sha256(data).hexdigest(),'style':'lamp','durationMs':560,'foldSupport':True,'islandHandoff':True},indent=2)+'\n')
print('Built',dest,'for headers',m[1]);print('No plugin was loaded. The loader also checks the running compositor commit.')
