-- Parm laptop profile: focused-display brightness shortcuts.
local focused_brightness_bindings = {
  "XF86MonBrightnessUp",
  "XF86MonBrightnessDown",
  "SHIFT + XF86MonBrightnessUp",
  "SHIFT + XF86MonBrightnessDown",
  "ALT + XF86MonBrightnessUp",
  "ALT + XF86MonBrightnessDown",
}

for _, binding in ipairs(focused_brightness_bindings) do
  hl.unbind(binding)
end

local brightness = "~/.config/omarchy/scripts/brightness-focused-display "
o.bind("XF86MonBrightnessUp", "Brightness up", brightness .. "+5%", { locked = true, repeating = true })
o.bind("XF86MonBrightnessDown", "Brightness down", brightness .. "5%-", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessUp", "Brightness maximum", brightness .. "100%", { locked = true, repeating = true })
o.bind("SHIFT + XF86MonBrightnessDown", "Brightness minimum", brightness .. "1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", brightness .. "+1%", { locked = true, repeating = true })
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", brightness .. "1%-", { locked = true, repeating = true })
