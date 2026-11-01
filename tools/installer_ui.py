"""Small terminal UI; no extra packages needed."""
import os,shutil,sys

class Terminal:
    def __init__(self,plain=False):
        self.tty=sys.stdout.isatty()
        self.color=self.tty and not plain and 'NO_COLOR' not in os.environ and os.environ.get('TERM','')!='dumb'
        self.width=min(84,max(40,shutil.get_terminal_size((80,24)).columns-4))
    def paint(self,text,style):
        codes={'accent':'38;5;115','muted':'2','bold':'1','error':'38;5;210'}
        return '\033['+codes[style]+'m'+str(text)+'\033[0m' if self.color else str(text)
    def header(self,subtitle='Shell installer'):
        print('\n  '+self.paint('A E T H E R','accent'))
        print('  '+self.paint(subtitle,'muted'))
        print('  '+self.paint('─'*(self.width-2),'muted')+'\n')
    def section(self,title):print('\n  '+self.paint(title,'bold'))
    def row(self,label,value):print('  '+label.ljust(19)+self.paint(value,'accent'))
    def info(self,text):print('  '+str(text))
    def success(self,text):print('\n  '+self.paint('Done','accent')+'  '+str(text))
    def error(self,text):print('\n  '+self.paint('Stopped','error')+'  '+str(text),file=sys.stderr)
    def progress(self,index,total,text):
        # One completed item per line keeps both terminal and redirected logs useful.
        print('  '+self.paint(f'{index:02}/{total:02}','accent')+'  '+str(text),flush=True)

UI=Terminal()

def interactive(args,home,show_plan):
    while True:
        UI.header('Make room for your desktop.')
        UI.row('Destination',str(home))
        UI.row('Shell','included')
        UI.row('Wallpapers','included' if args.wallpapers else 'off')
        UI.row('Window warp','build from source' if args.with_warp else 'off')
        UI.info('Existing files are backed up before replacement.')
        UI.section('Choose an action')
        UI.info('1  Toggle wallpapers')
        UI.info('2  Toggle window warp')
        UI.info('3  Preview file changes')
        UI.info('4  Install selected components')
        UI.info('0  Exit')
        try:choice=input('\n  Select [0–4]: ').strip()
        except EOFError:return False
        if choice=='0':return False
        if choice=='1':args.wallpapers=not args.wallpapers
        elif choice=='2':args.with_warp=not args.with_warp
        elif choice=='3':
            args.apply=False;show_plan(args,home)
            try:input('\n  Press Enter to return…')
            except EOFError:return False
        elif choice=='4':
            args.apply=False;show_plan(args,home)
            try:confirmed=input('\n  Install these files? [y/N]: ').strip().lower()
            except EOFError:return False
            if confirmed in ['y','yes']:args.apply=True;return True
            UI.info('No files changed.')
        else:UI.info('Choose a number from 0 to 4.')
