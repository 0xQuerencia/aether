#!/usr/bin/env python3
"""Copy an emoji, optionally paste it back into the focused app after closing Aether."""
import argparse,json,subprocess,time
from pathlib import Path

def active():
    try:return json.loads(subprocess.check_output(['hyprctl','-j','activewindow'],text=True))
    except (OSError,ValueError,subprocess.SubprocessError):return {}

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('mode',choices=['copy','insert']);p.add_argument('emoji');a=p.parse_args()
    if not a.emoji or len(a.emoji)>32:p.error('Expected one emoji sequence')
    target=active()
    subprocess.run(['wl-copy','--type','text/plain;charset=utf-8'],input=a.emoji.encode(),check=True)
    subprocess.run(['qs','-p',str(Path.home()/'.config/hypr/scripts/quickshell/Shell.qml'),'ipc','call','island','close'],check=True,stdout=subprocess.DEVNULL)
    if a.mode=='copy' or not target.get('address'):return
    time.sleep(.2)
    if active().get('address')!=target['address']:return
    terminal=target.get('class','').lower() in ['foot','footclient','kitty','alacritty','org.wezfurlong.wezterm','com.mitchellh.ghostty']
    command=['wtype','-M','ctrl']
    if terminal:command+=['-M','shift']
    command+=['-k','v']
    if terminal:command+=['-m','shift']
    command+=['-m','ctrl'];subprocess.run(command,check=True)
if __name__=='__main__':main()
