local core = require "core"
local command = require "core.command"


local function exec(cmd, keep_newline)
  local fp = io.popen(cmd, "r")
  local res = fp:read("*a")
  fp:close()
  return keep_newline and res or res:gsub("%\n$", "")
end


local function printfb_quote(str)
  local sub = {
    ["\\"] = "\\\\",
    [string.char(0)] = "\\0000",
    ["'"] = "'\\''",
  }
  return "'" .. str:gsub(".", sub) .. "'"
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
        return exec(
          "printf %b " .. printfb_quote(str:gsub("%\n$", "") .. "\n") .. " | " .. cmd,
          str:find("%\n$")
        )
      end)
    end)
  end,
})
