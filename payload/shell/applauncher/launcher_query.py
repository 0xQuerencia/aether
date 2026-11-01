#!/usr/bin/env python3
"""Keyboard launcher search and explicit actions; calculator never executes code."""
import ast, json, math, operator, os, re, subprocess, sys
from pathlib import Path
from app_fetcher import fetch_apps
HOME=Path.home(); RECENT=HOME/'.local/state/aether/launcher-recents.json'
def recent():
 try: return json.loads(RECENT.read_text())
 except (OSError,ValueError): return []
def score(query,name):
 q=query.casefold(); n=name.casefold()
 if not q: return 0
 if n.startswith(q): return 1000-len(n)
 if q in n: return 700-n.index(q)*4-len(n)
 cursor=0; positions=[]
 for char in q:
  cursor=n.find(char,cursor)
  if cursor<0: return -1
  positions.append(cursor); cursor+=1
 return 400-(positions[-1]-positions[0])*3-positions[0]-len(n)
def calculate(expression):
 if len(expression)>128: raise ValueError('Expression too long')
 tree=ast.parse(expression.replace('^','**'),mode='eval')
 binary={ast.Add:operator.add,ast.Sub:operator.sub,ast.Mult:operator.mul,ast.Div:operator.truediv,ast.Mod:operator.mod,ast.Pow:operator.pow}
 def visit(node,depth=0):
  if depth>20: raise ValueError('Expression too deep')
  if isinstance(node,ast.Constant) and type(node.value) in (int,float): value=node.value
  elif isinstance(node,ast.UnaryOp) and isinstance(node.op,(ast.UAdd,ast.USub)):
   value=visit(node.operand,depth+1)*(1 if isinstance(node.op,ast.UAdd) else -1)
  elif isinstance(node,ast.BinOp) and type(node.op) in binary:
   left,right=visit(node.left,depth+1),visit(node.right,depth+1)
   if isinstance(node.op,ast.Pow) and abs(right)>100: raise ValueError('Exponent too large')
   value=binary[type(node.op)](left,right)
  else: raise ValueError('Only arithmetic is supported')
  if not isinstance(value,(int,float)) or not math.isfinite(value) or abs(value)>1e100: raise ValueError('Result out of range')
  return value
 return format(visit(tree.body),'.12g')
def row(name,payload,icon='',kind='app',detail=''):
 return dict(name=name,exec=payload,icon=icon,kind=kind,detail=detail)
def is_calculation(q):
 return bool(re.fullmatch(r'[0-9.eE+*/%()^\-\s]+',q) and re.search(r'[+*/%^]|(?<!^)-',q))
def query(text):
 q=text.strip()
 if q.startswith('>'):
  cmd=q[1:].strip()
  return [row(cmd,cmd,'utilities-terminal','command','Run command')] if cmd else []
 if q.startswith('=') or is_calculation(q):
  try:
   answer=calculate(q[1:].strip() if q.startswith('=') else q); return [row(answer,answer,'accessories-calculator','copy','Enter to copy result')]
  except (ValueError,SyntaxError,ZeroDivisionError,OverflowError): return []
 if q.startswith('#'):
  proc=subprocess.run(['cliphist','list'],capture_output=True,text=True,timeout=3,check=True)
  matches=[]
  for line in proc.stdout.splitlines():
   ident,sep,content=line.partition('\t')
   if sep and ident.isdigit() and q[1:].strip().casefold() in content.casefold():
    matches.append(row(content[:120],ident,'edit-paste','clipboard','Copy from clipboard history'))
  return matches[:12]
 apps=fetch_apps(); history=recent()
 ranked=[]
 for app in apps:
  points=score(q,app['name'])
  if points<0: continue
  if app['exec'] in history: points+=(len(history)-history.index(app['exec']))*(1 if q else 100)
  ranked.append((points,app))
 ranked.sort(key=lambda item:(-item[0],item[1]['name'].casefold()))
 return [row(a['name'],a['exec'],a['icon'],detail='Recent' if not q and a['exec'] in history else '') for _,a in ranked[:12]]
def action(kind,payload,origin=None):
 if kind in ('app','command'):
  clean=re.sub(r'%[fFuUdDnNickvm]','',payload).strip()
  warp=HOME/'.local/bin/aether-warp'
  if kind=='app' and origin is not None and warp.is_file():
   subprocess.run([str(warp),'launch',origin,clean],check=True)
  else:
   subprocess.run([str(HOME/'.config/hypr/scripts/hl-dispatch'),'exec','--',clean],check=True)
  if kind=='app':
   items=[clean]+[entry for entry in recent() if entry!=clean]
   RECENT.parent.mkdir(parents=True,exist_ok=True); RECENT.parent.chmod(0o700)
   tmp=RECENT.with_suffix('.tmp'); tmp.write_text(json.dumps(items[:20])); tmp.chmod(0o600); tmp.replace(RECENT)
 elif kind=='copy': subprocess.run(['wl-copy','--',payload],check=True)
 elif kind=='clipboard':
  if not payload.isdigit(): raise ValueError('Invalid clipboard entry')
  value=subprocess.run(['cliphist','decode',payload],capture_output=True,check=True,timeout=3).stdout
  subprocess.run(['wl-copy'],input=value,check=True)
 else: raise ValueError('Unknown action')
if __name__=='__main__':
 if len(sys.argv)>1 and sys.argv[1]=='action': action(sys.argv[2],sys.argv[3],sys.argv[4] if len(sys.argv)>4 else None)
 else:
  q=sys.argv[1] if len(sys.argv)>1 else ''
  try: print(json.dumps({'query':q,'results':query(q)}))
  except (OSError,subprocess.SubprocessError): print(json.dumps({'query':q,'results':[]}))
