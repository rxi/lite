local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

local handled_events = {
  ["keypressed"]  = true,
  ["keyreleased"] = true,
  ["textinput"]   = true,
}

local state = "stopped"
local event_buffer = {}
local modkeys = {}

local on_event = core.on_event

core.on_event = function(type, ...)
  local res = on_event(type, ...)
  if state == "recording" and handled_events[type] then
    table.insert(event_buffer, { type, ... })
  end
  return res
end


local function clone(t)
  local res = {}
  for k, v in pairs(t) do res[k] = v end
  return res
end


local function predicate()
  return state ~= "playing"
end


command.add(predicate, {
  ["macro:toggle-record"] = function()
    if state == "stopped" then
      state = "recording"
      event_buffer = {}
      modkeys = clone(keymap.modkeys)
      core.log("Recording macro...")
    else
      state = "stopped"
      core.log("Stopped recording macro (%d events)", #event_buffer)
    end
  end,

  ["macro:play"] = function()
    state = "playing"
    core.log("Playing macro... (%d events)", #event_buffer)
    local mk = keymap.modkeys
    keymap.modkeys = clone(modkeys)
    for _, ev in ipairs(event_buffer) do
      on_event(table.unpack(ev))
      core.root_view:update()
    end
    keymap.modkeys = mk
    state = "stopped"
  end,
})


keymap.add {
  ["ctrl+shift+;"] = "macro:toggle-record",
  ["ctrl+;"] = "macro:play",
}
