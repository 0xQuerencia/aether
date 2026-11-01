#!/usr/bin/env python3
"""Manual integration check: exported shell in an owned nested Hyprland and private home/bus/runtime."""
import json,os,signal,subprocess as sp,tempfile,time,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'build';OUT.mkdir(exist_ok=True)
active=json.loads(sp.check_output(['hyprctl','-j','activewindow'],text=True));nested=None;shell=None
try:
 with tempfile.TemporaryDirectory(prefix='aether-shell-smoke-',ignore_cleanup_errors=True) as tmp:
  home=Path(tmp);sp.run(['bash',str(ROOT/'install.sh'),'--home',tmp,'--apply','--wallpapers'],check=True,stdout=sp.DEVNULL)
  colors=home/'.cache/quickshell/colors';colors.mkdir(parents=True);shutil.copyfile(home/'.config/aether/default-colors.json',colors/'qs_colors.json')
  config=home/'nested.lua';config.write_text('hl.monitor({output="",mode="preferred",position="auto",scale=1})\nhl.config({misc={disable_hyprland_logo=true},animations={enabled=false}})\n')
  log=(OUT/'nested-compositor.log').open('w');env=dict(os.environ,HYPRLAND_NO_SD_VARS='1',HYPRLAND_NO_SD_NOTIFY='1',DBUS_SESSION_BUS_ADDRESS='unix:path=/nonexistent')
  nested=sp.Popen(['Hyprland','--config',str(config)],env=env,stdout=log,stderr=sp.STDOUT)
  for _ in range(80):
   time.sleep(.1);instance=next((i for i in json.loads(sp.check_output(['hyprctl','instances','-j'],text=True)) if i['pid']==nested.pid),None)
   if instance:
    check=sp.run(['hyprctl','-i',instance['instance'],'-j','monitors'],capture_output=True,text=True)
    if check.returncode==0 and json.loads(check.stdout):break
  else:raise RuntimeError('Nested compositor failed')
  run=home/'run';run.mkdir(mode=0o700);hostrun=Path(os.environ['XDG_RUNTIME_DIR']);(run/instance['wl_socket']).symlink_to(hostrun/instance['wl_socket']);(run/'hypr').mkdir();(run/'hypr'/instance['instance']).symlink_to(hostrun/'hypr'/instance['instance'],target_is_directory=True)
  clientenv=dict(os.environ,HOME=tmp,XDG_CONFIG_HOME=str(home/'.config'),XDG_CACHE_HOME=str(home/'.cache'),XDG_STATE_HOME=str(home/'.local/state'),XDG_RUNTIME_DIR=str(run),WAYLAND_DISPLAY=instance['wl_socket'],HYPRLAND_INSTANCE_SIGNATURE=instance['instance'],QT_QPA_PLATFORM='wayland',PATH=str(home/'.local/bin')+':'+os.environ['PATH'])
  busconfig=home/'dbus.conf';busconfig.write_text('<busconfig><type>session</type><listen>unix:tmpdir=/tmp</listen><policy context="default"><allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/></policy></busconfig>')
  logfile=OUT/'exported-shell.log';loghandle=logfile.open('w');shell=sp.Popen(['dbus-run-session','--config-file='+str(busconfig),'--','qs','-p',str(home/'.config/hypr/scripts/quickshell/Shell.qml')],env=clientenv,stdout=loghandle,stderr=sp.STDOUT,start_new_session=True)
  time.sleep(9)
  logs=logfile.read_text();bad=[line for line in logs.splitlines() if any(x in line for x in ['Failed to load configuration','TypeError:','ReferenceError:','is not a type','module "'])]
  assert shell.poll() is None,(shell.returncode,logs[-3500:]);assert not bad,bad
  result=sp.run(['qs','-p',str(home/'.config/hypr/scripts/quickshell/Shell.qml'),'ipc','call','island','status'],env=clientenv,capture_output=True,text=True,timeout=5);assert result.returncode==0,result.stderr
  state=json.loads(result.stdout);assert state and state[0]['mode']=='collapsed',state
  (OUT/'nested-smoke-results.json').write_text(json.dumps({'passed':True,'privateHome':True,'privateBus':True,'privateRuntime':True,'shellResponded':True,'qmlErrors':bad,'runtime':'noctalia-qs 0.0.12'},indent=2))
  os.killpg(shell.pid,signal.SIGTERM);shell.wait(timeout=8)
  nested.terminate();nested.wait(timeout=8)
  print('Exported shell loaded and answered IPC in an isolated nested session.')
finally:
 if shell and shell.poll() is None:os.killpg(shell.pid,signal.SIGTERM);shell.wait(timeout=8)
 if nested and nested.poll() is None:nested.terminate();nested.wait(timeout=8)
 if active.get('address') and any(w['address']==active['address'] for w in json.loads(sp.check_output(['hyprctl','-j','clients'],text=True))):sp.run(['hyprctl','dispatch','hl.dsp.focus({window="address:'+active['address']+'"})'],stdout=sp.DEVNULL)
