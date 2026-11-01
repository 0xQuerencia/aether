#!/usr/bin/env python3
"""Read radio state and reversibly toggle software airplane mode through rfkill."""
import fcntl,json,subprocess,sys
from pathlib import Path
STATE=Path.home()/'.local/state/aether/radios'
def run(*args):return subprocess.check_output(list(args),text=True,stderr=subprocess.PIPE,timeout=8)
def devices():return json.loads(run('rfkill','--json'))['rfkilldevices']
def status(rows=None):
 rows=devices() if rows is None else rows
 return {'supported':bool(rows),'airplane':bool(rows) and all(row['soft']=='blocked' for row in rows),'hardwareBlocked':any(row['hard']=='blocked' for row in rows)}
def set_device(ident,blocked):run('rfkill','block' if blocked else 'unblock',str(int(ident)))
def toggle():
 rows=devices()
 if not rows:raise RuntimeError('No radio hardware found')
 original={str(int(row['id'])):row['soft']=='blocked' for row in rows}
 turning_on=not status(rows)['airplane'];cache=STATE/'previous.json'
 if turning_on:target={key:True for key in original}
 else:
  try:previous=json.loads(cache.read_text())
  except (OSError,ValueError):previous={}
  target={key:bool(previous.get(key,False)) for key in original}
 try:
  for key,blocked in target.items():
   if original[key]!=blocked:set_device(key,blocked)
 except Exception:
  for key,blocked in original.items():
   try:set_device(key,blocked)
   except subprocess.SubprocessError:pass
  raise
 if turning_on:cache.write_text(json.dumps(original));cache.chmod(0o600)
 elif cache.exists():cache.unlink()
 return status()
def main():
 STATE.mkdir(parents=True,exist_ok=True);STATE.chmod(0o700)
 with (STATE/'lock').open('w') as lock:
  fcntl.flock(lock,fcntl.LOCK_EX)
  return toggle() if len(sys.argv)>1 and sys.argv[1]=='toggle' else status()
if __name__=='__main__':
 try:print(json.dumps(main()))
 except (OSError,ValueError,subprocess.SubprocessError) as error:
  print(json.dumps({'supported':False,'airplane':False,'error':str(error)}));sys.exit(1)
