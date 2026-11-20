"""Keep bad user scale values from breaking monitor layouts."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("node"), "Node.js is needed for QML JS tests")
class ScaleTests(unittest.TestCase):
    def test_safe_scale_values(self):
        source = ROOT / "payload/shell/WindowRegistry.js"
        script = r"""
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const source = fs.readFileSync(process.argv[1], 'utf8').replace(/^\s*\.pragma library\s*/, '');
const layout = {};
vm.runInNewContext(source, layout);
assert.strictEqual(layout.getScale(1920, 1080, 1), 1);
assert.strictEqual(layout.getScale(1920, 1080, NaN), 1);
assert.strictEqual(layout.getScale(1920, 1080, Infinity), 1);
assert.strictEqual(layout.getScale(1920, 1080, -8), 0.8);
assert.strictEqual(layout.getScale(1920, 1080, 99), 1.4);
assert.strictEqual(layout.getScale(1920, 1080, '1.2'), 1.2);
assert.strictEqual(layout.getScale(0, 1080, 1.2), 1);
assert.strictEqual(layout.getScale(1920, 1.2), 1.2);
assert.ok(layout.getScale(1366, 768, 1) > 0.35);
"""
        result = subprocess.run(["node", "-e", script, str(source)],
                                capture_output=True, text=True, check=False)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_settings_reader_ignores_invalid_scale(self):
        source = (ROOT / "payload/shell/Scaler.qml").read_text()
        self.assertIn("Number.isFinite(requested)", source)
        self.assertIn("Math.max(0.8, Math.min(1.4, requested))", source)


if __name__ == "__main__":
    unittest.main()
