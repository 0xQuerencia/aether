"""Execute workspace wheel logic with Node when available."""
from pathlib import Path
import shutil
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(shutil.which("node"), "Node.js is needed for wheel behavior tests")
class WheelStepTests(unittest.TestCase):
    def test_large_impulse_is_bounded(self):
        source = ROOT / "payload/shell/panels/wheelstep.js"
        script = r"""
const fs = require('fs');
const vm = require('vm');
const assert = require('assert');
const code = fs.readFileSync(process.argv[1], 'utf8').replace(/^\\s*\\.pragma library\\s*/, '');
const wheel = {};
vm.runInNewContext(code, wheel);

let result = wheel.advance(wheel.createState(), 1000, 'unit', 0, 22, 250, 120, 0.01);
assert.strictEqual(result.step, 1);
assert.ok(result.state.accumulator <= 22, 'large swipe left excessive backlog');
result = wheel.drain(result.state, 120, 22, 250, 120);
assert.strictEqual(result.step, 1);
result = wheel.drain(result.state, 240, 22, 250, 120);
assert.strictEqual(result.step, 0);

let state = wheel.createState();
state = wheel.advance(state, 8, 'unit', 0, 22, 250, 120, 0.01).state;
state = wheel.advance(state, 8, 'unit', 10, 22, 250, 120, 0.01).state;
result = wheel.advance(state, 8, 'unit', 20, 22, 250, 120, 0.01);
assert.strictEqual(result.step, 1, 'small trackpad deltas should accumulate');

result = wheel.advance(result.state, -7, 'unit', 500, 22, 250, 120, 0.01);
assert.strictEqual(result.step, 0, 'idle input should reset stale momentum');
"""
        completed = subprocess.run(
            ["node", "-e", script, str(source)], capture_output=True, text=True, check=False
        )
        self.assertEqual(completed.returncode, 0, completed.stderr)


if __name__ == "__main__":
    unittest.main()
