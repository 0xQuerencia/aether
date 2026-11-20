"""Focus timer UI presets use Aether's existing persistent timer backend."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FocusPresetTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = (ROOT / "payload/shell/panels/TimerClockPanel.qml").read_text()

    def test_focus_break_durations(self):
        for value in ("{minutes:25,label:\"Focus\"", "{minutes:5,label:\"Short break\"", "{minutes:15,label:\"Long break\""}):
            self.assertIn(value, self.source)

    def test_presets_reuse_live_timer_backend(self):
        self.assertIn("onClicked:root.preset(modelData.minutes*60,modelData.label)", self.source)
        self.assertIn("LiveActivities.add(duration,name.text)", self.source)
        self.assertIn("Keys.onEscapePressed", self.source)


if __name__ == "__main__":
    unittest.main()
