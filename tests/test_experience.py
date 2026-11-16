"""Offline tests for Aether's optional desktop/media helpers."""
import importlib.machinery
from concurrent.futures import ThreadPoolExecutor
import importlib.util
from pathlib import Path
import sys
# Avoid creating Python bytecode inside the installable payload during CI.
sys.dont_write_bytecode = True
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


def load(name, path):
    loader = importlib.machinery.SourceFileLoader(name, str(ROOT / path))
    spec = importlib.util.spec_from_loader(name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class ExperienceTests(unittest.TestCase):
    def test_lrc_timing_and_line_order(self):
        lyrics = load("aether_lyrics_test", "payload/bin/aether-lyrics")
        result = lyrics.parse_lrc("[00:03.50]Third\n[00:01.5]First\n[00:02.75][00:04.0]Echo\n[offset:100]\n[00:99.0]Late")
        self.assertEqual([line["text"] for line in result[:4]], ["First", "Echo", "Third", "Echo"])
        self.assertEqual([line["time"] for line in result[:4]], [1.5, 2.75, 3.5, 4.0])

    def test_lrc_does_not_treat_metadata_as_lyrics(self):
        lyrics = load("aether_lyrics_metadata_test", "payload/bin/aether-lyrics")
        self.assertEqual(lyrics.parse_lrc("[artist:Example]\n[offset:100]"), [])

    def test_monitor_config_safe_and_atomic(self):
        monitor = load("aether_monitor_test", "payload/bin/aether-monitor")
        with tempfile.TemporaryDirectory() as directory:
            monitor.ROOT = Path(directory)
            self.assertFalse(monitor.get("eDP-1")["desktopClock"])
            self.assertTrue(monitor.set_value("eDP-1", "desktopClock", "on")["desktopClock"])
            self.assertFalse(monitor.set_value("eDP-1", "desktopClock", "toggle")["desktopClock"])
            self.assertAlmostEqual(monitor.set_value("DP-1", "panelScale", "1.25")["panelScale"], 1.25)
            with self.assertRaises(ValueError):
                monitor.set_value("../oops", "desktopClock", "on")
            with self.assertRaises(ValueError):
                monitor.set_value("DP-1", "panelScale", "4")

    def test_monitor_toggles_are_serialized(self):
        monitor = load("aether_monitor_concurrency_test", "payload/bin/aether-monitor")
        with tempfile.TemporaryDirectory() as directory:
            monitor.ROOT = Path(directory)
            with ThreadPoolExecutor(max_workers=6) as pool:
                list(pool.map(lambda _: monitor.set_value("eDP-1", "desktopClock", "toggle"), range(20)))
            self.assertFalse(monitor.get("eDP-1")["desktopClock"])

    def test_lrclib_retry_after(self):
        lyrics = load("aether_lyrics_retry_test", "payload/bin/aether-lyrics")
        self.assertEqual(lyrics.retry_seconds("120"), 120)
        self.assertEqual(lyrics.retry_seconds(None), 60)

    def test_vpn_parsing_and_id_check(self):
        vpn = load("aether_vpn_test", "payload/bin/aether-vpn")
        self.assertEqual(vpn.split_escaped(r"uuid:vpn:My\: office VPN"), ["uuid", "vpn", "My: office VPN"])
        self.assertTrue(vpn.UUID.fullmatch("12345678-1234-1234-1234-123456789abc"))
        self.assertFalse(vpn.UUID.fullmatch("1234; touch /tmp/unsafe"))

    def test_launcher_actions_are_not_shell_commands(self):
        sys.path.insert(0, str(ROOT / "payload/shell/applauncher"))
        launcher = load("aether_launcher_test", "payload/shell/applauncher/launcher_query.py")
        records = launcher.query("@lyrics")
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]["kind"], "island")
        self.assertEqual(records[0]["exec"], "lyrics")
        self.assertTrue(all(r["kind"] in ("island", "scheme", "theme") for r in launcher.query("@")))

    def test_optional_python_helpers_compile(self):
        paths = ["payload/bin/aether-lyrics", "payload/bin/aether-monitor", "payload/bin/aether-vpn",
                 "payload/shell/applauncher/launcher_query.py", "payload/scripts/aether-theme.py"]
        for path in paths:
            with self.subTest(path=path):
                compile((ROOT / path).read_text(encoding="utf-8"), path, "exec")


if __name__ == "__main__":
    unittest.main()
