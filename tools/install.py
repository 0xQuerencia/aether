#!/usr/bin/env python3
"""Transactional shell-only installer. No compositor settings or system packages are changed."""
from pathlib import Path
import argparse,datetime,fcntl,hashlib,json,os,re,shutil,subprocess,sys,tempfile
ROOT=Path(__file__).resolve().parents[1]
from installer_ui import UI, Terminal, interactive

def digest(path):
    if path.is_symlink():return 'symlink:'+os.readlink(path)
    if path.is_file():return hashlib.sha256(path.read_bytes()).hexdigest()+':'+oct(path.stat().st_mode&0o777)
    if path.is_dir():
        h=hashlib.sha256()
        for p in sorted(path.rglob('*')):
            h.update(str(p.relative_to(path)).encode());h.update(digest(p).encode() if not p.is_dir() or p.is_symlink() else b'dir')
        return h.hexdigest()
    return 'missing'

def write_json(p,data):
    t=p.with_suffix('.tmp');t.write_text(json.dumps(data,indent=2)+'\n');t.chmod(0o600);os.replace(t,p)

def target(home,rel):
    if Path(rel).is_absolute() or '..' in Path(rel).parts:raise ValueError('Invalid target: '+rel)
    p=home/rel
    if not p.parent.resolve().is_relative_to(home.resolve()):raise ValueError('Target parent leaves home: '+rel)
    return p

def plan(wallpapers=False):
    jobs=[('shell','.config/hypr/scripts/quickshell',False),('config/aether','.config/aether',False)]
    for folder,dest in [('scripts','.config/hypr/scripts'),('bin','.local/bin'),('services','.config/systemd/user')]:
        jobs += [(str(p.relative_to(ROOT/'payload')),dest+'/'+p.name,False) for p in sorted((ROOT/'payload'/folder).iterdir()) if p.is_file()]
    jobs += [('config/aether/palettes.json','.config/hypr/aether-palettes.json',True),('config/aether/settings.json','.config/hypr/settings.json',True)]
    if wallpapers:jobs += [('wallpapers','.local/share/aether/wallpapers',False)]
    return jobs

def rendered(src,dst,home):
    if src.is_symlink():raise ValueError('Payload symlink refused: '+str(src))
    if src.is_dir():
        dst.mkdir()
        for p in sorted(src.iterdir()):rendered(p,dst/p.name,home)
    else:
        raw=src.read_bytes()
        if b'\0' not in raw:
            try:raw=raw.decode().replace('@HOME@',str(home)).encode()
            except UnicodeError:pass
        dst.write_bytes(raw);dst.chmod(src.stat().st_mode&0o777)

def rollback(home,backup):
    journal=backup/'transaction.json';data=json.loads(journal.read_text())
    if data['home']!=str(home):raise ValueError('Backup belongs to another home')
    # Check everything before rollback.
    for e in data['entries']:
        p=target(home,e['target'])
        if str(p.parent.resolve())!=e['parent']:raise ValueError('Target parent changed: '+str(p))
        if (e['state']=='installed' or (e['state']=='backed-up' and os.path.lexists(p))) and digest(p)!=e['installedHash']:raise ValueError('File changed after install; rollback refused: '+str(p))
    for e in reversed(data['entries']):
        if e['state']=='restored':continue
        p=target(home,e['target']);old=backup/e['backup'];kept=backup/('removed-'+e['backup'])
        if e['state'] in ['installed','backed-up'] and os.path.lexists(p):
            if digest(p)!=e['installedHash']:raise ValueError('Refusing to replace changed target: '+str(p))
            os.replace(p,kept)
        if os.path.lexists(old):os.replace(old,p)
        e['state']='restored';write_json(journal,data)
    data['status']='restored';write_json(journal,data)
    UI.success('Previous files restored.')
    UI.row('Retained files',str(backup))

def install(args,home):
    from audit import audit
    errors=audit()
    if errors:raise ValueError("Source audit failed: "+"; ".join(errors))
    jobs=plan(args.wallpapers)
    if args.with_warp:
        jobs.append(('../build/warp','.local/share/aether-warp',False))
    UI.header('Install preview' if not args.apply else 'Installing your shell')
    UI.row('Destination',str(home))
    UI.row('Wallpapers','included' if args.wallpapers else 'off')
    UI.row('Window warp','build from source' if args.with_warp else 'off')
    replacements=0;kept=0
    if not args.apply:UI.section('Files')
    for src,rel,seed in jobs:
        p=target(home,rel)
        if seed and os.path.lexists(p):
            if not args.apply:UI.info('keep     '+rel)
            kept+=1
        elif os.path.lexists(p):
            if not args.apply:UI.info('back up  '+rel)
            replacements+=1
        elif not args.apply:UI.info('add      '+rel)
    UI.section('Summary')
    UI.info(f'{len(jobs)-kept} targets to install · {replacements} backups · {kept} existing defaults kept')
    if not args.apply:
        UI.info('Plan only. Add --apply to install, or --interactive for the menu.')
        return
    if os.geteuid()==0:raise ValueError('Run as a normal user, not root.')
    
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+',str(home)):raise ValueError('This release requires a home path without spaces or shell metacharacters.')
    if args.with_warp:
        UI.section('Build window warp')
        buildlog=ROOT/'build/warp-build.log';buildlog.parent.mkdir(exist_ok=True)
        with buildlog.open('w') as log:
            result=subprocess.run([sys.executable,str(ROOT/'tools/build-warp.py')],stdout=log,stderr=subprocess.STDOUT)
        if result.returncode:raise ValueError('Warp build failed. No files installed. See '+str(buildlog))
        UI.info('Built against your installed Hyprland headers.')
    state=home/'.local/state/aether-installer' ;state.mkdir(parents=True,exist_ok=True,mode=0o700)
    with (state/'operation.lock').open('a') as lock:
        fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
        backup=state/'backups'/datetime.datetime.now().strftime('%Y%m%d-%H%M%S-%f');backup.mkdir(parents=True,mode=0o700)
        journal=backup/'transaction.json';data={'home':str(home),'status':'installing','entries':[]};write_json(journal,data)
        UI.section('Installing')
        completed=0;total=sum(not (seed and os.path.lexists(target(home,rel))) for src,rel,seed in jobs)
        try:
            for src,rel,seed in jobs:
                p=target(home,rel)
                if seed and os.path.lexists(p):continue
                p.parent.mkdir(parents=True,exist_ok=True)
                # Stage beside the target for atomic renames.
                stage=Path(tempfile.mkdtemp(prefix='.aether-stage-',dir=p.parent))
                try:
                    new=stage/'new';rendered(ROOT/'payload'/src,new,home)
                    e={'target':rel,'parent':str(p.parent.resolve()),'backup':str(len(data['entries'])),'state':'planned','installedHash':digest(new)}
                    data['entries'].append(e);write_json(journal,data)
                    if os.path.lexists(p):os.replace(p,backup/e['backup'])
                    e['state']='backed-up';write_json(journal,data)
                    os.replace(new,p);e['state']='installed';write_json(journal,data)
                    completed+=1;UI.progress(completed,total,rel)
                finally:shutil.rmtree(stage)
            data['status']='installed';write_json(journal,data)
        except BaseException:
            UI.info("Restoring files from this attempt…")
            rollback(home,backup);raise
        UI.success('Aether is installed.')
        UI.row('Backup',str(backup))
        UI.section('Next steps')
        UI.info('1  Review ~/.config/aether/integration.lua')
        UI.info('2  Add it to your Hyprland Lua config; see docs/SETUP.md')
        UI.info('3  Stop your existing shell, then run: aether-session')
        UI.section('Undo this install')
        import shlex
        UI.info('./install.sh --rollback '+shlex.quote(str(backup)))
        UI.info('Services have not been started.')

def main():
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--interactive',action='store_true',help='open the guided terminal menu')
    p.add_argument('--plain',action='store_true',help='disable terminal colours')
    p.add_argument('--apply',action='store_true',help='install; default is a read-only plan')
    p.add_argument('--wallpapers',action='store_true',help='install the included Aether wallpapers')
    p.add_argument('--with-warp',action='store_true',help='build the native plugin using installed matching headers; never load it during installation')
    p.add_argument('--home',type=Path,default=Path.home(),help='target home; used for isolated validation')
    p.add_argument('--rollback',type=Path,help='restore a transaction if installed files remain unchanged')
    args=p.parse_args();home=args.home.expanduser().absolute()
    import installer_ui
    global UI
    UI=Terminal(args.plain);installer_ui.UI=UI
    if sys.version_info<(3,11):raise ValueError('Python 3.11+ required')
    if args.rollback:
        backup=args.rollback.expanduser().resolve();base=home/'.local/state/aether-installer/backups'
        if not backup.is_relative_to(base.resolve()):raise ValueError('Backup must be inside this home\'s installer backup directory')
        lockpath=base.parent/'operation.lock';lockpath.parent.mkdir(parents=True,exist_ok=True)
        with lockpath.open('a') as lock:
            fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB);rollback(home,backup)
    else:
        menu=args.interactive or (len(sys.argv)==1 and sys.stdin.isatty() and sys.stdout.isatty())
        if menu and not interactive(args,home,install):
            UI.info('Exited. No files changed.');return
        install(args,home)

if __name__=='__main__':
    try:main()
    except KeyboardInterrupt:UI.info('Cancelled.');sys.exit(130)
    except (OSError,ValueError,subprocess.SubprocessError) as e:UI.error(str(e));sys.exit(1)
