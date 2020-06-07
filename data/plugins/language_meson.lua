local syntax = require "core.syntax"

syntax.add {
  files = "meson.build$",
  comment = "#",
  patterns = {
    { pattern = { "#", "\n" },            type = "comment"  },
    { pattern = { '"', '"', '\\' },       type = "string"   },
    { pattern = { "'", "'", '\\' },       type = "string"   },
    { pattern = { "'''", "'''" },         type = "string"   },
    { pattern = "0x[%da-fA-F]+",          type = "number"   },
    { pattern = "-?%d+%d*",               type = "number"   },
    { pattern = "[%+%-=/%%%*!]",          type = "operator" },
    { pattern = "[%a_][%w_]*%f[(]",       type = "function" },
    { pattern = "[%a_][%w_]*",            type = "symbol"   },
  },
  symbols = {
    ["if"]         = "keyword",
    ["then"]       = "keyword",
    ["else"]       = "keyword",
    ["elif"]       = "keyword",
    ["endif"]      = "keyword",
    ["foreach"]    = "keyword",
    ["endforeach"] = "keyword",
    ["break"]      = "keyword",
    ["continue"]   = "keyword",
    ["and"]        = "keyword",
    ["not"]        = "keyword",
    ["or"]         = "keyword",
    ["in"]         = "keyword",
    ["true"]       = "literal",
    ["false"]      = "literal",
  },
}

