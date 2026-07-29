-- Application bindings.
-- Omarchy loads its application bindings before this file.  Remove the
-- defaults that this personal list replaces so one shortcut starts one app.
local personal_application_bindings = {

  "SUPER + CTRL + SHIFT + F",
  "SUPER + SHIFT + M",
  "SUPER + SHIFT + A",
  "SUPER + SHIFT + CTRL + A",
  "SUPER + CTRL + A",
  "SUPER + SHIFT + C",
  "SUPER + SHIFT + E",
  "SUPER + SHIFT + ALT + E",
  "SUPER + SHIFT + Y",
  "SUPER + SHIFT + ALT + G",
  "SUPER + SHIFT + CTRL + G",
  "SUPER + SHIFT + P",
  "SUPER + SHIFT + S",
  "SUPER + SHIFT + X",
  "SUPER + SHIFT + ALT + X",
}

for _, binding in ipairs(personal_application_bindings) do
  hl.unbind(binding)
end


o.bind("SUPER + CTRL + SHIFT + F", "File manager", { omarchy = "dolphin" })
o.bind("SUPER + SHIFT + M", "Music", "mpv --player-operation-mode=pseudo-gui --shuffle ~/Videos")
o.bind("SUPER + SHIFT + K", "Kate", { tui = "kate" })

-- Open the System menu through its explicit alias. The literal "system"
-- route is shadowed by OpenSnitch's "system" desktop-entry keyword.
hl.unbind("SUPER + ESCAPE")
o.bind("SUPER + ESCAPE", "System menu", "omarchy-menu toggle power-menu")

-- Web app bindings.
local zen = "zen-browser"
local web_ai = "~/.config/omarchy/scripts/web-ai-scratchpad "
o.bind("SUPER + SHIFT + A", "ChatGPT", web_ai .. "toggle chatgpt")
o.bind("SUPER + SHIFT + CTRL + A", "Claude", web_ai .. "toggle claude")
o.bind("SUPER + CTRL + A", "Web AI", "omarchy-shell shell toggle local.web-ai '{}'")
o.bind("SUPER + SHIFT + C", "Calendar", { launch = zen .. " --new-window https://calendar.google.com/calendar/weeks/" })
o.bind("SUPER + SHIFT + E", "Email", { launch = zen .. " --new-window https://gmail.com" })
o.bind("SUPER + SHIFT + ALT + E", "New email",
    { launch = zen .. " --new-window https://app.gmail.com/messages/new?display=standalone&new_window=true" })
o.bind("SUPER + SHIFT + Y", "YouTube", { launch = zen .. " --new-window https://youtube.com/" })
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", { launch = zen .. " --new-window https://web.whatsapp.com/" })
o.bind(
    "SUPER + SHIFT + CTRL + G",
    "Google Messages",
    { launch = zen .. " --new-window https://messages.google.com/web/conversations" }
)
o.bind("SUPER + SHIFT + P", "Google Photos", { launch = zen .. " --new-window https://photos.google.com/" })
o.bind("SUPER + SHIFT + S", "Google Maps", { launch = zen .. " --new-window https://maps.google.com/" })
o.bind("SUPER + SHIFT + X", "X", { launch = zen .. " --new-window https://x.com/" })
o.bind("SUPER + SHIFT + ALT + X", "X Post", { launch = zen .. " --new-window https://x.com/compose/post" })

-- Add extra bindings below.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Overwrite existing bindings with hl.unbind() first if needed.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { omarchy = "walker -m symbols" })
