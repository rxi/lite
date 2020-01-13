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


syntax.add {
  files = "%.lua$",
  comment = "--",
  patterns = {
    { pattern = { '"', '"', '\\' },       type = "string"   },
    { pattern = { "'", "'", '\\' },       type = "string"   },
    { pattern = { "%[%[", "%]%]" },       type = "string"   },
    { pattern = { "--%[%[", "%]%]"},      type = "comment"  },
    { pattern = "%-%-.-\n",               type = "comment"  },
    { pattern = "-?0x%x+",                type = "number"   },
    { pattern = "-?%d+[%d%.eE]*",         type = "number"   },
    { pattern = "-?%.?%d+",               type = "number"   },
    { pattern = "%.%.%.?",                type = "operator" },
    { pattern = "[<>~=]=",                type = "operator" },
    { pattern = "[%+%-=/%*%^%%#<>,%.]",   type = "operator" },
    { pattern = "[%[%]%(%){}]",           type = "bracket"  },
    { pattern = "[%a_][%w_]*%s*%f[(\"{]", type = "function" },
    { pattern = "[%a_][%w_]*",            type = "symbol"   },
  },
  symbols = {
    ["if"]       = "keyword",
    ["then"]     = "keyword",
    ["else"]     = "keyword",
    ["elseif"]   = "keyword",
    ["end"]      = "keyword",
    ["do"]       = "keyword",
    ["function"] = "keyword",
    ["repeat"]   = "keyword",
    ["until"]    = "keyword",
    ["while"]    = "keyword",
    ["for"]      = "keyword",
    ["break"]    = "keyword",
    ["return"]   = "keyword",
    ["local"]    = "keyword",
    ["in"]       = "keyword",
    ["not"]      = "keyword",
    ["and"]      = "keyword",
    ["or"]       = "keyword",
    ["self"]     = "keyword2",
    ["true"]     = "literal",
    ["false"]    = "literal",
    ["nil"]      = "literal",
  },
}


syntax.add {
  files = { "%.c$", "%.h$", "%.inl$", "%.cpp$", "%.hpp$" },
  comment = "//",
  patterns = {
    { pattern = "//.-\n",                  type = "comment"  },
    { pattern = { "/%*", "%*/" },          type = "comment"  },
    { pattern = { "#", "[^\\]\n" },        type = "comment"  },
    { pattern = { '"', '"', '\\' },        type = "string"   },
    { pattern = { "'", "'", '\\' },        type = "string"   },
    { pattern = "-?0x%x+",                 type = "number"   },
    { pattern = "-?%d+[%d%.eE]*f?",        type = "number"   },
    { pattern = "-?%.?%d+f?",              type = "number"   },
    { pattern = "[%+%-=/%*%^%%<>!~|&,%.]", type = "operator" },
    { pattern = "[%[%]%(%){}]",            type = "bracket"  },
    { pattern = "[%a_][%w_]*%f[(]",        type = "function" },
    { pattern = "[%a_][%w_]*",             type = "symbol"   },
  },
  symbols = {
    ["if"]       = "keyword",
    ["then"]     = "keyword",
    ["else"]     = "keyword",
    ["elseif"]   = "keyword",
    ["do"]       = "keyword",
    ["while"]    = "keyword",
    ["for"]      = "keyword",
    ["break"]    = "keyword",
    ["continue"] = "keyword",
    ["return"]   = "keyword",
    ["goto"]     = "keyword",
    ["struct"]   = "keyword",
    ["typedef"]  = "keyword",
    ["enum"]     = "keyword",
    ["extern"]   = "keyword",
    ["static"]   = "keyword",
    ["const"]    = "keyword",
    ["inline"]   = "keyword",
    ["switch"]   = "keyword",
    ["case"]     = "keyword",
    ["default"]  = "keyword",
    ["auto"]     = "keyword",
    ["const"]    = "keyword",
    ["void"]     = "keyword",
    ["int"]      = "keyword2",
    ["float"]    = "keyword2",
    ["double"]   = "keyword2",
    ["char"]     = "keyword2",
    ["unsigned"] = "keyword2",
    ["bool"]     = "keyword2",
    ["true"]     = "literal",
    ["false"]    = "literal",
    ["NULL"]     = "literal",
  },
}


syntax.add {
  files = { "%.md$", "%.markdown$" },
  patterns = {
    { pattern = "\\.",                    type = "normal"   },
    { pattern = { "<!%-%-", "%-%->" },    type = "comment"  },
    { pattern = { "```", "```" },         type = "string"   },
    { pattern = { "`", "`", "\\" },       type = "string"   },
    { pattern = { "~~", "~~", "\\" },     type = "keyword2" },
    { pattern = "%-%-%-+",                type = "comment" },
    { pattern = "%*%s+",                  type = "operator" },
    { pattern = { "%*", "[%*\n]", "\\" }, type = "operator" },
    { pattern = { "%_", "[%_\n]", "\\" }, type = "keyword2" },
    { pattern = "#.-\n",                  type = "keyword"  },
    { pattern = "!?%[.*%]%(.*%)",         type = "function" },
    { pattern = "https?://%S+",           type = "function" },
  },
  symbols = { },
}


return syntax
