# Aether Experience: optional desktop features

This addition builds on Aether's existing island, per-app mixer, notification history, and task manager. It does **not** replace those components.

## Open panels

After adding the updated `integration.lua` keybinds to your Hyprland Lua configuration:

| Shortcut | Feature |
|---|---|
| Alt+Shift+D | Fullscreen dashboard (CPU, GPU, memory, storage, network, battery, music) |
| Alt+Shift+L | Synchronized lyrics (when music metadata is available) |
| Alt+Shift+V | VPN management for existing NetworkManager profiles |

The same panels are available from the launcher with `@dashboard`, `@lyrics`, and `@vpn`. Type `@` to list other safe actions and themes. The pre-existing `>` command mode remains separate.

## Synchronized lyrics

Aether queries [LRCLIB](https://lrclib.net/docs) **only when the lyrics panel is opened or the song changes while it is open**. There is no polling of LRCLIB in the background. Results cache under `~/.cache/aether/lyrics` (30-day successful cache, one-hour missing-result cache). It also reads optional local LRC files named `Artist - Track.lrc` in `~/Music/lyrics` before trying the network.

The lyrics interface follows the elapsed playback position reported by playerctl/MPRIS. Some players expose stale position metadata, so timing can vary. If a service responds with 429, wait and try again; the helper does not loop or bypass rate limits.

## Optional CAVA spectrum

Install `cava` separately if you want live spectrum bars. Aether uses the PulseAudio compatibility input, which works with common PipeWire setups; no audio is transmitted to a web server by the spectrum renderer. The `SpectrumBars` widget starts CAVA only while an enabled widget is visible. If CAVA is absent the UI degrades to empty bars.

The wallpaper spectrum and desktop clock are **disabled by default**. In Settings > Desktop widgets, toggle them for the *current monitor*. Reduced motion stops the CAVA renderer and decorative bar movement.

## Per-monitor configuration

Settings are stored under `~/.config/aether/monitors/<output>.json` and are independent of Hyprland's display mode configuration. For scripting:

```bash
python3 ~/.local/bin/aether-monitor get eDP-1
python3 ~/.local/bin/aether-monitor set eDP-1 desktopClock on
python3 ~/.local/bin/aether-monitor set eDP-1 wallpaperVisualizer on
python3 ~/.local/bin/aether-monitor set eDP-1 panelScale 1.15
```

Display names may be listed with `hyprctl monitors -j`. Each file is written atomically with private permissions. If your wallpaper provider occupies a higher layer than Aether's bottom-layer widgets, desktop overlays may be obscured. This is a compositor/layer arrangement issue, not a reason to disable your wallpaper provider.

## VPN

VPN management controls only saved NetworkManager `vpn` or `wireguard` connection UUIDs. It does not execute arbitrary user-supplied commands, prompt for or store credentials, or create VPN profiles. Use NetworkManager to import or configure new profiles first. The panel reports connection errors and refreshes status while open.

## Colors and launcher

The launcher recognizes `@theme` for the three curated themes and `@colors` for Matugen scheme variants: tonal spot, neutral, and content. Recoloring the existing wallpaper retains Aether's theme snapshot and rollback behavior.

## Testing

```bash
python3 -m unittest discover -s tests -v
python3 tools/audit.py
python3 tests/nested-smoke.py   # requires an owned nested Hyprland environment
```

The static CI and unit tests do not validate native desktop presentation. Test monitor hotplug, CAVA responsiveness, MPRIS synchronization, and VPN connections on actual hardware before treating these additions as production-ready.
