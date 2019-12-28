local core = require "core"
local command = require "core.command"
local CommandView = require "core.commandview"

local function has_commandview()
  return core.active_view:is(CommandView)
end


command.add(has_commandview, {
  ["command:submit"] = function()
    core.active_view:submit()
  end,

  ["command:complete"] = function()
    core.active_view:complete()
  end,

  ["command:escape"] = function()
    core.active_view:exit()
  end,

  ["command:select-previous"] = function()
    core.active_view:move_suggestion_idx(1)
  end,

  ["command:select-next"] = function()
    core.active_view:move_suggestion_idx(-1)
  end,
})
