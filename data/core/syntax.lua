local common = require "core.common"

local syntax = {}
syntax.items = {}

local plain_text_syntax = { patterns = {}, symbols = {} }


function syntax.add(t)
  table.insert(syntax.items, t)
end


function syntax.get(filename)
  for i = #syntax.items, 1, -1 do
    local t = syntax.items[i]
    if common.match_pattern(filename, t.files) then
      return t
    end
  end
  return plain_text_syntax
end


return syntax
