local home = os.getenv("HOME")

package.path = "/usr/share/parm/?.lua;"
  .. home .. "/.config/parm/?.lua;"
  .. home .. "/.config/?.lua;"
  .. package.path

require("config.hypr.default")

local imported_monitors = home .. "/.config/parm/hypr/imported-monitors.lua"
local monitors = io.open(imported_monitors, "r")
if monitors then
  monitors:close()
  dofile(imported_monitors)
end

local override_path = home .. "/.config/parm/hypr/overrides.lua"
local override = io.open(override_path, "r")
if override then
  override:close()
  dofile(override_path)
end
