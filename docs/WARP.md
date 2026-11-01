# Warp

Aether Warp transforms the real window texture through a temporary GPU mesh. New windows open from the island; explicit folds play the transform backwards, then move the window to `special:minimized`. Restore returns it to its saved workspace. No window is closed by a fold.

The C++ source targets the installed Hyprland 0.56.2 API. Hyprland's internal plugin ABI changes, so this repository ships no `.so`. Native source compatibility with another Hyprland version must be tested; a compile error should be reported with the compositor/header version rather than worked around by bypassing the loader checks.

Install `base-devel`, `pkgconf` and the development headers matching the compositor you run. Then use `./install.sh --apply --with-warp` to compile and install a backed-up build. The build records the header commit and binary SHA-256. It does not unload/load a plugin or change your running compositor.

From a running Hyprland session:

```bash
aether-warp load
aether-warp status
```

If the build commit differs from the running compositor, the loader refuses the plugin and normal opening/fold/restore still work. Use `aether-warp off` to disable future animations. Never copy another person's precompiled plugin over your own build. The installer replaces files atomically rather than rewriting the inode of a loaded shared library; restart or unload the old plugin through your own workflow before expecting the rebuilt plugin to be active.

Reduced motion disables decorative arrivals and native warps. Minimized-window recovery data is private, scoped to the compositor instance, and not included in the repository.
