local keymap = require "core.keymap"

local on_key_pressed = keymap.on_key_pressed
local on_key_released = keymap.on_key_released

local function remap_key(k)
  return k:gsub("command", "ctrl")
          :gsub("option",  "alt")
end

function keymap.on_key_pressed(k)
  return on_key_pressed(remap_key(k))
end

function keymap.on_key_released(k)
  return on_key_released(remap_key(k))
end

