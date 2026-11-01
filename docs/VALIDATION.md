# Validation and release limits

## Completed locally

- `python3 tools/audit.py`: payload and warp source match their SHA-256/mode manifest; no configured credential patterns, private home paths or forbidden runtime artifacts found. A pattern scanner cannot prove the absence of every possible secret.
- Nine real installer integration checks, covering menu preview/exit, declining installation, confirmed installation, interrupted-write recovery, and the original file-safety checks: read-only plan, install plus rollback, edited-file refusal before any rollback mutation, external symlink parent refusal, and recovery after a simulated write failure part-way through installation. The fixture has a symlinked Hyprland profile, an existing compositor config, settings and a terminal config; those are checked for preservation.
- `python3 tests/nested-smoke.py`: exported payload installed to a temporary home, then loaded in an owned nested Hyprland with a private session bus and runtime directory. The exported shell answered its `island status` IPC. No QML type/load/JavaScript errors were found. Runtime: noctalia-qs 0.0.12. The private runtime intentionally does not expose the host PipeWire server, and the existing host Polkit agent prevents a second registration for the same subject, so this check does not validate fresh-machine audio/authentication.
- `python3 tools/build-warp.py`: current source compiled against the installed Hyprland 0.56.2 headers and wrote commit/hash metadata. It did not load another plugin into the live desktop.
- Earlier live development checks on the author's real desktop cover fold/restore, native warp rendering, centered wing growth and fullscreen hiding. These are evidence for the source design, not proof that a freshly installed machine has matching hardware/services.

## Still required for a public release

A clean CachyOS/Arch user installation should test login startup, notifications, clipboard collection, audio, radios, recording, file drops, wallpaper selection, display previews and rollback. Physical HDMI/USB display negotiation and mixed-DPI monitors have not been established by the source export test. Run your own lock/PAM test before adopting the optional lock entry point.

The owner confirmed authorship of the original shell/profile. The original Aether code and configuration use the MIT licence. Product photography and personal screenshots remain excluded.

The repository is `0xQuerencia/aether`. Each public release should also be checked by cloning its tag and running the read-only installer plan.

## Re-run

```bash
python3 tools/audit.py
python3 -m unittest discover -s tests -v
python3 tests/nested-smoke.py       # requires a running Hyprland session; temporarily opens an owned nested compositor
python3 tools/build-warp.py        # requires matching headers/compiler; build only
python3 tools/package.py
```

The package builder produces `dist/aether-shell-source.tar.gz` and `dist/SHA256SUMS`; local build outputs, Git history and logs are excluded. Source changes intentionally require regenerating `manifest.json` with `python3 tools/audit.py --write-manifest` after reviewing the changes.
