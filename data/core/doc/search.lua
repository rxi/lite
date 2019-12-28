local search = {}

local default_opt = {}


local function pattern_lower(str)
  if str:sub(1, 1) == "%" then
    return str
  end
  return str:lower()
end


local function init_args(doc, line, col, text, opt)
  opt = opt or default_opt
  line, col = doc:sanitize_position(line, col)

  if opt.no_case then
    if opt.pattern then
      text = text:gsub("%%?.", pattern_lower)
    else
      text = text:lower()
    end
  end

  return doc, line, col, text, opt
end


function search.find(doc, line, col, text, opt)
  doc, line, col, text, opt = init_args(doc, line, col, text, opt)

  for line = line, #doc.lines do
    local line_text = doc.lines[line]
    if opt.no_case then
      line_text = line_text:lower()
    end
    local s, e = line_text:find(text, col, not opt.pattern)
    if s then
      return line, s, line, e + 1
    end
    col = 1
  end

  if opt.wrap then
    opt = { no_case = opt.no_case, pattern = opt.pattern }
    return search.find(doc, 1, 1, text, opt)
  end
end


return search
