-- Add dofile(os.getenv("HOME") .. "/.config/aether/integration.lua") to your
-- Hyprland Lua config. Put it INSIDE your binding submap if you use one.
-- This changes no monitor, GPU, decoration, layout or terminal configuration.
local home = os.getenv("HOME")
local shell = home .. "/.config/hypr/scripts/quickshell/Shell.qml"
local function panel(name)
    return hl.dsp.exec_cmd("qs -p " .. shell .. " ipc call island " .. name)
end
hl.bind("ALT + SPACE", panel("launcher"))
hl.bind("SUPER + I", panel("settings"))
hl.bind("SUPER + TAB", panel("overview"))
hl.bind("SUPER + period", panel("emoji"))
hl.bind("SUPER + V", panel("clipboard"))
hl.bind("ALT + W", panel("wallpaper"))
hl.bind("ALT + P", panel("palette"))
hl.bind("SUPER + SHIFT + N", panel("fold"))
hl.bind("SUPER + ALT + N", panel("folds"))
-- Locking is deliberately not rebound; keep your current tested lock binding.
hl.on("hyprland.start", function()
    hl.exec_cmd(home .. "/.local/bin/aether-session")
end)
