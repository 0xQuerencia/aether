"""Live activity clock should avoid unnecessary idle updates."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ActivityClockTests(unittest.TestCase):
    def test_adaptive_tick_preserves_active_countdowns(self):
        source = (ROOT / "payload/shell/LiveActivities.qml").read_text()
        self.assertIn('readonly property bool countingTimer:timers.some(timer=>timer.status==="running")', source)
        self.assertIn("interval:root.countingTimer?500:1000", source)
        self.assertIn("onTriggered:root.now=Date.now()/1000", source)


if __name__ == "__main__":
    unittest.main()
