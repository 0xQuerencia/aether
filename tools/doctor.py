#!/usr/bin/env python3
"""Read-only dependency diagnostics; never start services or change configuration."""
import shutil,subprocess,sys
required=['qs','hyprctl','python3','jq','wl-copy','wl-paste','cliphist','wtype','grim','slurp','wpctl','nmcli','bluetoothctl','matugen','awww']
optional=['ffmpeg','wf-recorder','brightnessctl','powerprofilesctl','hyprsunset','mpv','socat','openssl','notify-send']
missing=[]
for cmd in required+optional:
 found=shutil.which(cmd);print(('OK      ' if found else 'MISSING ')+cmd+(' (optional)' if cmd in optional else '')+((' — '+found) if found else ''))
 if not found and cmd in required:missing.append(cmd)
for cmd in [['qs','--version'],['hyprctl','version']]:
 if shutil.which(cmd[0]):
  p=subprocess.run(cmd,capture_output=True,text=True,timeout=8);print((p.stdout or p.stderr).splitlines()[0] if p.stdout or p.stderr else 'No version reported')
print('Known tested runtime: noctalia-qs 0.0.12, Hyprland Lua 0.56.2. Other runtimes need validation.')
print('For Polkit support, the runtime must provide Quickshell.Services.Polkit.')
sys.exit(1 if missing else 0)
