local p = {}

function p.bind(keys, description, dispatcher, options)
  local opts = options or {}
  opts.description = description
  if type(dispatcher) == "string" then
    dispatcher = hl.dsp.exec_cmd(dispatcher)
  end
  hl.bind(keys, dispatcher, opts)
end

function p.launch(command)
  return "uwsm-app -- " .. command
end

function p.start(command)
  hl.on("hyprland.start", function()
    hl.exec_cmd(command)
  end)
end

return p
