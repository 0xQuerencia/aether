#!/usr/bin/env python3
import shutil
"""Cache real Matugen dry-run previews and cleanly stop owned workers on cancellation."""
import hashlib, json, os, signal, subprocess, sys
from pathlib import Path
active = None

def cancelled(signum, frame):
    if active is not None and active.poll() is None:
        active.terminate()
        try: active.wait(timeout=2)
        except subprocess.TimeoutExpired:
            active.kill(); active.wait()
    raise SystemExit(128 + signum)

signal.signal(signal.SIGTERM, cancelled)
signal.signal(signal.SIGINT, cancelled)
path = Path(sys.argv[1])
matugen = Path(shutil.which('matugen') or str(Path.home() / '.cargo/bin/matugen'))
identity = f'{path.resolve()}:{path.stat().st_mtime_ns}:{path.stat().st_size}:{matugen.stat().st_mtime_ns}:v1'
cache = Path.home() / '.cache/aether/palettes' / (hashlib.sha256(identity.encode()).hexdigest() + '.json')
try:
    result = json.loads(cache.read_text())
except (OSError, ValueError):
    variants = []
    for label, scheme in [('Soft', 'scheme-tonal-spot'), ('Muted', 'scheme-neutral'), ('Rich', 'scheme-content')]:
        try:
            active = subprocess.Popen([str(matugen), 'image', str(path), '--source-color-index', '0', '--dry-run', '--json', 'hex', '--type', scheme], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
            try: output, errors = active.communicate(timeout=20)
            except subprocess.TimeoutExpired:
                active.terminate(); active.communicate(timeout=2); raise
            if active.returncode: raise ValueError('Matugen preview failed')
            colors = json.loads(output)['colors']
            variants.append({'label': label, 'scheme': scheme, 'colors': [colors[name]['dark']['color'] for name in ('surface', 'primary', 'secondary', 'tertiary', 'on_surface')]})
        except (subprocess.SubprocessError, OSError, KeyError, ValueError) as exc:
            print(f'{label}: {exc}', file=sys.stderr)
        finally: active = None
    result = {'path': str(path), 'variants': variants}
    if len(variants) == 3:
        cache.parent.mkdir(parents=True, exist_ok=True)
        temp = cache.with_suffix(f'.{os.getpid()}.tmp')
        temp.write_text(json.dumps(result)); temp.replace(cache)
print(json.dumps(result))
