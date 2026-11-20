"""Keyboard navigation guardrails for the launcher."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class LauncherUiTests(unittest.TestCase):
    def test_navigation_uses_the_island_model(self):
        source = (ROOT / "payload/shell/panels/LauncherPanel.qml").read_text()
        self.assertIn("const count = island.appResults.count;", source)
        self.assertNotIn("appResults.count - 1", source)
        self.assertIn("if (count < 1) return;", source)

    def test_keyboard_shortcuts_keep_search_focused(self):
        source = (ROOT / "payload/shell/panels/LauncherPanel.qml").read_text()
        self.assertIn("Keys.onUpPressed: launcherContent.moveSelection(-1)", source)
        self.assertIn("Keys.onDownPressed: launcherContent.moveSelection(1)", source)
        self.assertIn("Qt.Key_K", source)
        self.assertIn("Qt.Key_PageDown", source)
        self.assertIn("Qt.Key_PageUp", source)


if __name__ == "__main__":
    unittest.main()
