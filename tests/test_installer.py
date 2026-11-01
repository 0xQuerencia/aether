import importlib.util,json,os,subprocess,sys,tempfile,unittest
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT/'tools'))
class InstallerTests(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(prefix='aether-install-test-');self.home=Path(self.tmp.name)
  (self.home/'.config').mkdir();(self.home/'profile/hypr/scripts/quickshell').mkdir(parents=True)
  (self.home/'.config/hypr').symlink_to(self.home/'profile/hypr',target_is_directory=True)
  (self.home/'profile/hypr/scripts/quickshell/original').write_text('original shell')
  (self.home/'profile/hypr/hyprland.lua').write_text('user compositor settings')
  (self.home/'profile/hypr/settings.json').write_text('{"personal":true}')
  (self.home/'.config/foot').mkdir();(self.home/'.config/foot/foot.ini').write_text('original terminal')
 def tearDown(self):self.tmp.cleanup()
 def cli(self,*args,ok=True):
  r=subprocess.run([sys.executable,str(ROOT/'tools/install.py'),'--home',str(self.home),*map(str,args)],capture_output=True,text=True)
  if ok:self.assertEqual(r.returncode,0,r.stdout+r.stderr)
  else:self.assertNotEqual(r.returncode,0,r.stdout+r.stderr)
  return r
 def backup(self):return next((self.home/'.local/state/aether-installer/backups').iterdir())
 def preserved(self):
  self.assertTrue((self.home/'.config/hypr').is_symlink())
  self.assertEqual((self.home/'profile/hypr/hyprland.lua').read_text(),'user compositor settings')
  self.assertEqual((self.home/'.config/foot/foot.ini').read_text(),'original terminal')
  self.assertEqual((self.home/'profile/hypr/settings.json').read_text(),'{"personal":true}')
 def test_plan_does_not_write(self):
  self.cli();self.assertFalse((self.home/'.local').exists());self.preserved()
 def test_install_and_rollback_preserve_symlink_profile(self):
  self.cli('--apply','--wallpapers');self.preserved()
  self.assertTrue((self.home/'.config/hypr/scripts/quickshell/Shell.qml').is_file())
  self.assertFalse((self.home/'.local/bin/flow-island').exists())
  self.assertNotIn('Dictation',(self.home/'.config/hypr/scripts/quickshell/SettingsWindow.qml').read_text())
  self.assertTrue((self.home/'.local/share/aether/wallpapers/graphite-flow.png').is_file())
  self.assertNotIn('@HOME@',(self.home/'.config/aether/integration.lua').read_text())
  self.cli('--rollback',self.backup());self.preserved()
  self.assertEqual((self.home/'.config/hypr/scripts/quickshell/original').read_text(),'original shell')
  self.assertFalse((self.home/'.local/bin/aether-drop').exists())
 def test_edit_guard_preflights_whole_rollback(self):
  self.cli('--apply');p=self.home/'.config/hypr/scripts/quickshell/Shell.qml';p.write_text('my edits')
  other=self.home/'.local/bin/aether-drop';before=other.read_bytes()
  self.cli('--rollback',self.backup(),ok=False)
  self.assertEqual(p.read_text(),'my edits');self.assertEqual(other.read_bytes(),before)
 def test_external_parent_symlink_is_refused(self):
  (self.home/'.config/hypr').unlink()
  with tempfile.TemporaryDirectory(prefix='aether-outside-') as out:
   (self.home/'.config/hypr').symlink_to(out,target_is_directory=True)
   self.cli('--apply',ok=False);self.assertEqual(list(Path(out).iterdir()),[])
 def test_failure_restores_already_replaced_files(self):
  spec=importlib.util.spec_from_file_location('installer',ROOT/'tools/install.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
  real=m.rendered
  def fail(src,dst,home):
   if src.name=='aether-drop':raise OSError('simulated failed write')
   return real(src,dst,home)
  m.rendered=fail
  import argparse,contextlib,io
  args=argparse.Namespace(wallpapers=False,with_warp=False,apply=True)
  with contextlib.redirect_stdout(io.StringIO()),self.assertRaises(OSError):m.install(args,self.home)
  self.preserved();self.assertEqual((self.home/'.config/hypr/scripts/quickshell/original').read_text(),'original shell')
  self.assertFalse((self.home/'.config/aether').exists())
 def test_menu_preview_and_exit_do_not_write(self):
  r=subprocess.run([sys.executable,str(ROOT/'tools/install.py'),'--home',str(self.home),'--interactive'],input='1\n3\n\n0\n',capture_output=True,text=True)
  self.assertEqual(r.returncode,0,r.stderr);self.assertIn('Wallpapers',r.stdout);self.assertIn('Plan only',r.stdout)
  self.assertNotIn('\x1b[',r.stdout);self.assertFalse((self.home/'.local').exists());self.preserved()
 def test_declining_menu_install_does_not_write(self):
  r=subprocess.run([sys.executable,str(ROOT/'tools/install.py'),'--home',str(self.home),'--interactive'],input='4\nn\n0\n',capture_output=True,text=True)
  self.assertEqual(r.returncode,0,r.stderr);self.assertFalse((self.home/'.local').exists());self.preserved()
 def test_confirmed_menu_install(self):
  r=subprocess.run([sys.executable,str(ROOT/'tools/install.py'),'--home',str(self.home),'--interactive','--plain'],input='4\ny\n',capture_output=True,text=True)
  self.assertEqual(r.returncode,0,r.stderr);self.assertIn('Aether is installed',r.stdout)
  self.assertTrue((self.home/'.local/bin/aether-session').is_file());self.preserved()
 def test_interrupt_restores_previous_files(self):
  spec=importlib.util.spec_from_file_location('installer_interrupt',ROOT/'tools/install.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
  real=m.rendered
  def interrupt(src,dst,home):
   if src.name=='aether-drop':raise KeyboardInterrupt()
   return real(src,dst,home)
  m.rendered=interrupt
  import argparse,contextlib,io
  args=argparse.Namespace(wallpapers=False,with_warp=False,apply=True)
  with contextlib.redirect_stdout(io.StringIO()),self.assertRaises(KeyboardInterrupt):m.install(args,self.home)
  self.assertEqual((self.home/'.config/hypr/scripts/quickshell/original').read_text(),'original shell');self.preserved()
if __name__=='__main__':unittest.main()
