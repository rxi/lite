local core = require "core"
local config = require "core.config"
local command = require "core.command"
local keymap = require "core.keymap"


local function wordwrap_text(text, limit)
  local t = {}
  local n = 0

  for word in text:gmatch("%S+") do
    if n + #word > limit then
      table.insert(t, "\n")
      n = 0
    elseif #t > 0 then
      table.insert(t, " ")
    end
    table.insert(t, word)
    n = n + #word + 1
  end

  return table.concat(t)
end


command.add("core.docview", {
  ["reflow:reflow"] = function()
    local doc = core.active_view.doc
    doc:replace(function(text)
      local prefix_set = "[^%w\n%[%](){}`'\"]*"

      -- get line prefix and trailing whitespace
      local prefix1 = text:match("^\n*" .. prefix_set)
      local prefix2 = text:match("\n(" .. prefix_set .. ")", #prefix1+1)
      local trailing = text:match("%s*$")
      if not prefix2 or prefix2 == "" then
        prefix2 = prefix1
      end

      -- strip all line prefixes and trailing whitespace
      text = text:sub(#prefix1+1, -#trailing - 1):gsub("\n" .. prefix_set, "\n")

      -- split into blocks, wordwrap and join
      local line_limit = config.line_limit - #prefix1
      local blocks = {}
      text = text:gsub("\n\n", "\0")
      for block in text:gmatch("%Z+") do
        table.insert(blocks, wordwrap_text(block, line_limit))
      end
      text = table.concat(blocks, "\n\n")

      -- add prefix to start of lines
      text = prefix1 .. text:gsub("\n", "\n" .. prefix2) .. trailing

      return text
    end)
  end,
})


keymap.add {
  ["ctrl+shift+q"] = "reflow:reflow"
}
