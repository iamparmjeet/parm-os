local p = require("config.hypr.helpers")

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.config({
  general = {
    gaps_in = 2,
    gaps_out = 2,
    border_size = 0,
    layout = "dwindle",
    resize_on_border = true,
    allow_tearing = false,
  },
  decoration = {
    rounding = 10,
    shadow = { enabled = true, range = 16, render_power = 2 },
    blur = { enabled = true, size = 6, passes = 2 },
  },
  input = {
    kb_layout = "us",
    follow_mouse = 1,
    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,
    touchpad = {
      natural_scroll = false,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },
  dwindle = {
    preserve_split = true,
    force_split = 2,
  },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    focus_on_activate = true,
  },
  ecosystem = {
    no_update_news = true,
  },
})

hl.curve("parmOut", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "parmOut" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "parmOut" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "parmOut", style = "slide" })

p.bind("SUPER + RETURN", "Terminal", p.launch("alacritty"))
p.bind("SUPER + SPACE", "Launcher", "parmctl shell launcher")
p.bind("SUPER + W", "Close window", hl.dsp.window.close())
p.bind("SUPER + F", "Fullscreen", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
p.bind("SUPER + T", "Toggle floating", hl.dsp.window.float({ action = "toggle" }))
p.bind("SUPER + CTRL + SHIFT + F", "Files", p.launch("dolphin"))
p.bind("SUPER + SHIFT + K", "Kate", p.launch("kate"))
p.bind("SUPER + SHIFT + M", "Shuffle Videos", p.launch("mpv --shuffle ~/Videos"))
p.bind("SUPER + CTRL + COMMA", "Parm Settings", "parmctl settings")

for workspace = 1, 5 do
  p.bind("SUPER + " .. workspace, "Workspace " .. workspace,
    hl.dsp.focus({ workspace = tostring(workspace) }))
  p.bind("SUPER + SHIFT + " .. workspace, "Move to workspace " .. workspace,
    hl.dsp.window.move({ workspace = tostring(workspace) }))
end

p.bind("SUPER + LEFT", "Focus left", hl.dsp.focus({ direction = "l" }))
p.bind("SUPER + RIGHT", "Focus right", hl.dsp.focus({ direction = "r" }))
p.bind("SUPER + UP", "Focus up", hl.dsp.focus({ direction = "u" }))
p.bind("SUPER + DOWN", "Focus down", hl.dsp.focus({ direction = "d" }))

p.bind("XF86AudioRaiseVolume", "Volume up", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+", {
  locked = true,
  repeating = true,
})
p.bind("XF86AudioLowerVolume", "Volume down", "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-", {
  locked = true,
  repeating = true,
})
p.bind("XF86AudioMute", "Mute", "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle", { locked = true })
p.bind("XF86MonBrightnessUp", "Brightness up", "parmctl brightness +5", {
  locked = true,
  repeating = true,
})
p.bind("XF86MonBrightnessDown", "Brightness down", "parmctl brightness -5", {
  locked = true,
  repeating = true,
})

p.start("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP")
p.start("dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP")
p.start("uwsm-app -- hypridle")
p.start("uwsm-app -- /usr/lib/polkit-kde-authentication-agent-1")
p.start("quickshell -n -p /usr/share/parm/shell")

return p
