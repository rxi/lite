local syntax = {}

syntax.items = {}

local plain_text_syntax = { patterns = {}, symbols = {} }


local function matches_pattern(text, pattern)
  if type(pattern) == "string" then
    return text:find(pattern)
  end
  for _, p in ipairs(pattern) do
    if matches_pattern(text, p) then return true end
  end
  return false
end


function syntax.add(t)
  table.insert(syntax.items, t)
end


function syntax.get(filename)
  for i = #syntax.items, 1, -1 do
    local t = syntax.items[i]
    if matches_pattern(filename, t.files) then
      return t
    end
  end
  return plain_text_syntax
end


return syntax
