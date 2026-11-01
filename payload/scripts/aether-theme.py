#!/usr/bin/env python3
"""Apply curated Aether themes through the installed Matugen templates, with snapshots."""
import fcntl, hashlib, json, os, re, shutil, subprocess, sys, time, tomllib
from pathlib import Path
HOME=Path.home()
STATE=HOME/'.local/state/aether/themes'
THEMES={'midnight-forest':('Midnight Forest','#64b69c'), 'warm-sand':('Warm Sand','#c5a37c'), 'blue-hour':('Blue Hour','#8daec8')}
def run(args):
 return subprocess.run([str(a) for a in args],check=True,capture_output=True,text=True,timeout=90).stdout
def refresh_apps():
 try:
  subprocess.run(['bash',str(HOME/'.config/hypr/scripts/quickshell/wallpaper/matugen_reload.sh')],capture_output=True,timeout=15)
 except (OSError,subprocess.SubprocessError):
  pass
def files():
 config=tomllib.loads((HOME/'.config/aether/matugen/config.toml').read_text())
 paths=[Path(os.path.expanduser(t['output_path'])) for t in config['templates'].values()]
 return list(dict.fromkeys(paths+[HOME/'.cache/quickshell/wallpaper_picker/current_wallpaper.png',STATE/'current.json',STATE/'wallpaper-palette.json',HOME/'.cache/current_wallpaper']))
def snapshot():
 target=STATE/str(time.time_ns()); target.mkdir(parents=True)
 items=[]
 for index,p in enumerate(files()):
  item={'path':str(p),'exists':p.exists()}
  if p.exists():
   shutil.copyfile(p,target/str(index)); item['backup']=str(index); item['mode']=p.stat().st_mode & 0o777
  items.append(item)
 wallpapers=[]
 for line in run(['awww','query']).splitlines():
  match=re.match(r'^:\s*([^:]+):.*currently displaying: image: (.*)$',line)
  if match: wallpapers.append({'output':match[1].strip(),'path':match[2]})
 # First selection has no previous image to restore.
 data={'files':items,'wallpapers':wallpapers,'previous':(STATE/'latest').read_text() if (STATE/'latest').exists() else None}
 (target/'snapshot.json').write_text(json.dumps(data,indent=2))
 return target,data
def restore(target,data,guard=True):
 if guard:
  for item in data['files']:
   p=Path(item['path']); actual=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
   if actual!=item.get('after'): raise RuntimeError('Theme output changed since apply: '+str(p))
 for item in data['files']:
  p=Path(item['path'])
  if item['exists']:
   p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes((target/item['backup']).read_bytes()); p.chmod(item['mode'])
  elif p.exists(): p.unlink()
 run(['python3',HOME/'.config/hypr/scripts/aether-sync-apps.py','--live-only'])
 for wallpaper in data['wallpapers']:
  run(['awww','img',wallpaper['path'],'-o',wallpaper['output'],'-t','none'])
def apply_source(name, label, wallpaper, seed=None, scheme='scheme-tonal-spot', change_wallpaper=True, mode='theme'):
 if change_wallpaper and not wallpaper.is_file(): raise FileNotFoundError(wallpaper)
 target,data=snapshot()
 try:
  command=[shutil.which('matugen') or str(HOME/'.cargo/bin/matugen'),'color','hex',seed] if seed else [shutil.which('matugen') or str(HOME/'.cargo/bin/matugen'),'image',wallpaper,'--source-color-index','0']
  run(command+['--config',HOME/'.config/aether/matugen/config.toml','-t',scheme])
  run(['python3',HOME/'.config/hypr/scripts/aether-sync-apps.py'])
  if change_wallpaper:
   run(['awww','img',wallpaper,'-t','fade','--transition-duration','0.6'])
   lockwall=HOME/'.cache/quickshell/wallpaper_picker/current_wallpaper.png'
   lockwall.parent.mkdir(parents=True,exist_ok=True); shutil.copyfile(wallpaper,lockwall)
   (HOME/'.cache/current_wallpaper').write_text(str(wallpaper)+'\n')
   colors=json.loads((HOME/'.cache/quickshell/colors/qs_colors.json').read_text())
   (STATE/'wallpaper-palette.json').write_text(json.dumps({'path':str(wallpaper),'colors':[colors[key] for key in ['blue','sapphire','peach','text','surface0','overlay0']]}))
  current_wallpaper=str(wallpaper) if change_wallpaper else (data['wallpapers'][0]['path'] if data['wallpapers'] else '')
  (STATE/'current.json').write_text(json.dumps({'id':name,'label':label,'wallpaper':current_wallpaper,'mode':mode}))
  for item in data['files']:
   file=Path(item['path']);item['after']=hashlib.sha256(file.read_bytes()).hexdigest() if file.exists() else None
  (target/'snapshot.json').write_text(json.dumps(data,indent=2));(STATE/'latest').write_text(str(target))
  refresh_apps()
 except Exception:
  restore(target,data,False);raise
 return {'ok':True,'theme':name,'selection':'wallpaper' if mode=='wallpaper' else name,'snapshot':str(target)}
def apply(name, change_wallpaper=True):
 if name not in THEMES: raise ValueError('Unknown theme')
 wallpaper=HOME/'.local/share/aether/wallpapers'/f'{name}.png'
 return apply_source(name,THEMES[name][0],wallpaper,THEMES[name][1],change_wallpaper=change_wallpaper,mode='theme' if change_wallpaper else 'palette')
def apply_wallpaper(path, scheme='scheme-tonal-spot'):
 if scheme not in ['scheme-tonal-spot','scheme-neutral','scheme-content']: raise ValueError('Unsupported palette variant')
 wallpaper=Path(path).expanduser().resolve()
 if not wallpaper.is_file(): raise FileNotFoundError(wallpaper)
 if wallpaper.suffix.lower() in ['.mp4','.mkv','.mov','.webm']:
  frames=STATE/'frames';frames.mkdir(exist_ok=True)
  frame=frames/(hashlib.sha256(f'{wallpaper}:{wallpaper.stat().st_mtime_ns}'.encode()).hexdigest()+'.png')
  if not frame.exists(): run(['ffmpeg','-v','error','-y','-ss','1','-i',wallpaper,'-frames:v','1',frame])
  wallpaper=frame
 known=next((name for name in THEMES if wallpaper==(HOME/'.local/share/aether/wallpapers'/f'{name}.png').resolve()),None)
 seed=THEMES[known][1] if known and scheme=='scheme-tonal-spot' else None
 return apply_source(known or 'wallpaper',THEMES[known][0] if known else wallpaper.stem,wallpaper,seed,scheme,mode='wallpaper')
def palette_data():
 palettes=json.loads((HOME/'.config/hypr/aether-palettes.json').read_text())
 for item in palettes: item['kind']='palette'
 try:
  auto=json.loads((STATE/'wallpaper-palette.json').read_text())
  if any('image: '+auto['path'] in line for line in run(['awww','query']).splitlines()):
   palettes.insert(0,{'id':'wallpaper','label':'Wallpaper colours','kind':'wallpaper','path':auto['path'],'colors':auto['colors']})
 except (OSError,ValueError): pass
 return palettes
def main():
 STATE.mkdir(parents=True,exist_ok=True); STATE.chmod(0o700)
 with (STATE/'lock').open('w') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  action=sys.argv[1] if len(sys.argv)>1 else 'list'
  if action=='palette-data': return palette_data()
  if action=='wallpaper': return apply_wallpaper(sys.argv[2],sys.argv[3] if len(sys.argv)>3 else 'scheme-tonal-spot')
  if action=='list':
   return [{'id':key,'label':value[0],'accent':value[1],'wallpaper':str(HOME/'.local/share/aether/wallpapers'/f'{key}.png')} for key,value in THEMES.items()]
  if action=='apply': return apply(sys.argv[2])
  if action=='palette': return apply(sys.argv[2],False)
  if action=='restore':
   target=Path((STATE/'latest').read_text()); data=json.loads((target/'snapshot.json').read_text()); restore(target,data)
   if data.get('previous'): (STATE/'latest').write_text(data['previous'])
   else: (STATE/'latest').unlink()
   refresh_apps()
   return {'ok':True,'restored':str(target)}
  raise ValueError('Use list, apply THEME, or restore')
if __name__=='__main__':
 try: print(json.dumps(main()))
 except Exception as exc:
  print(json.dumps({'ok':False,'error':str(exc)})); sys.exit(1)
