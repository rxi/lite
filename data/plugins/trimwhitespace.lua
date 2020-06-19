local core = require "core"
local command = require "core.command"
local Doc = require "core.doc"


local function trim_trailing_whitespace(doc)
  local cline, ccol = doc:get_selection()
  for i = 1, #doc.lines do
    local old_text = doc:get_text(i, 1, i, math.huge)
    local new_text = old_text:gsub("%s*$", "")

    -- don't remove whitespace which would cause the caret to reposition
    if cline == i and ccol > #new_text then
      new_text = old_text:sub(1, ccol - 1)
    end

    if old_text ~= new_text then
      doc:insert(i, 1, new_text)
      doc:remove(i, #new_text + 1, i, math.huge)
    end
  end
end


command.add("core.docview", {
  ["trim-whitespace:trim-trailing-whitespace"] = function()
    trim_trailing_whitespace(core.active_view.doc)
  end,
})


local save = Doc.save
Doc.save = function(self, ...)
  trim_trailing_whitespace(self)
  save(self, ...)
end
