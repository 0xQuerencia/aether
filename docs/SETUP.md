# Setup

## Install prerequisites

Run `tools/dependencies.sh` to inspect missing Arch/CachyOS packages. `--apply` invokes `sudo pacman -S --needed` for available missing packages with the package manager's normal prompt. It does not refresh package databases, upgrade the system, change drivers, or bootstrap an AUR helper. Resolve stale mirrors using your distribution's normal full-update process if downloads fail.

`noctalia-qs` is available in the author's CachyOS repositories. If it is unavailable on your distribution, consult its [upstream instructions](https://github.com/noctalia-dev/noctalia-qs). The dependency tool reports unavailable packages and stops instead of silently installing a different runtime.

Matugen and awww package names vary; install them through your distribution or your existing AUR helper after reviewing the package. `tools/doctor.py` checks executable availability. Recording needs ffmpeg and wf-recorder; OCR needs `tesseract` and the language data you use. Wireless control needs running NetworkManager and BlueZ services. Aether does not enable or reconfigure those system services.

The shell can use awww for wallpaper selection. It does not need to replace another provider to display the island, but running wallpaper providers simultaneously can obscure one another.

## Connect to Hyprland

First inspect the generated `~/.config/aether/integration.lua`. It contains the optional keybindings and session startup hook; remove bindings that you already use for other actions.

Add this to your existing Hyprland Lua config:

```lua
dofile(os.getenv("HOME") .. "/.config/aether/integration.lua")
```

If your bindings live in a named submap, place that line inside its existing `hl.define_submap` callback. Aether does not switch or replace your submaps. Reload your own config using your usual workflow. The integration file uses the current [Hyprland Lua API](https://hypr.land/news/26_lua/); it is not for older hyprlang configurations.

For the current session, stop your existing bar/notification shell using its own controls, then run:

```bash
aether-session
```

The session helper refuses to start another shell while a different Quickshell process is running. It imports the compositor environment and starts Aether's shell, timer/headphone service, and local Continue receiver. The receiver creates its own private device identity and receive code; none is shared by this repository. No files are sent automatically. Stop the Continue service if you do not want phone handoff listening on your network.

The shell registers a notification server and a Polkit agent. Avoid running two notification servers or two Polkit agents for the same session. Your existing Polkit agent may remain the active agent; in that case Aether's agent can report a registration warning. Installation does not kill or disable other desktop processes.

On the next login, the Lua integration's `hyprland.start` callback runs `aether-session`. No display manager or system service is replaced. To stop Aether now, run `aether-session stop`.

## Keybindings provided by the integration

| Shortcut | Action |
|---|---|
| Alt+Space | Launcher |
| Super+I | Settings |
| Super+Tab | Overview |
| Super+Period | Emoji picker |
| Super+V | Clipboard |
| Alt+W | Wallpapers |
| Alt+P | Palette |
| Super+Shift+N | Fold active window into island |
| Super+Alt+N | Minimized-window shelf |

Your lock-screen shortcut is deliberately retained. You may manually integrate Aether's `scripts/lock.sh` after testing its PAM flow on your own system. No authentication test can be performed for another user's password during installation.

## Wallpaper and palette

`--wallpapers` installs five generated wallpapers in `~/.local/share/aether/wallpapers`. It does not change the current wallpaper during installation. After starting the wallpaper provider, choose one through Alt+W, or run:

```bash
python3 ~/.config/hypr/scripts/aether-theme.py apply midnight-forest
```

The portable release uses its own `~/.config/aether/matugen/config.toml`. It generates shell colours only; it does not replace your global Matugen config or recolour your terminal, editor, GTK or Qt applications. Theme snapshots preserve prior shell colours and any prior awww image. On the first selection, if awww has no previous image, there is no earlier image for the snapshot to restore.

Weather is optional. Copy `~/.config/hypr/scripts/quickshell/calendar/.env.example` to `.env`, fill in your own weather key/city, and keep the file private.

## File destinations

The installer prints every target before installation. Main targets are the shell directory, support scripts under `~/.config/hypr/scripts`, helper commands under `~/.local/bin`, `~/.config/aether`, and Aether user service files. `settings.json` and palette defaults are created only when absent. Existing settings are not replaced.

The current release requires a home path without spaces or shell metacharacters because inherited scripts embed home paths inside shell, Lua and QML commands. Unsupported paths fail before installation begins. Symlinked parent directories are accepted only when they resolve inside the selected home.
