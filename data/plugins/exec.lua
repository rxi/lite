local core = require "core"
local command = require "core.command"


local function exec(cmd)
  local fp = io.popen(cmd, "r")
  local res = fp:read("*a")
  fp:close()
  return res:gsub("%\n$", "")
end


command.add("core.docview", {
  ["exec:insert"] = function()
    core.command_view:enter("Insert Result Of Command", function(cmd)
      core.active_view.doc:text_input(exec(cmd))
    end)
  end,

  ["exec:replace"] = function()
    core.command_view:enter("Replace With Result Of Command", function(cmd)
      core.active_view.doc:replace(function(str)
        return exec(string.format("echo %q | %s", str, cmd))
      end)
    end)
  end,
})
