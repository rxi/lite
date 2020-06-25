local syntax = require "core.syntax"

syntax.add {
  files = { "%.md$", "%.markdown$" },
  patterns = {
    { pattern = "\\.",                    type = "normal"   },
    { pattern = { "<!%-%-", "%-%->" },    type = "comment"  },
    { pattern = { "```", "```" },         type = "string"   },
    { pattern = { "``", "``", "\\" },     type = "string"   },
    { pattern = { "`", "`", "\\" },       type = "string"   },
    { pattern = { "~~", "~~", "\\" },     type = "keyword2" },
    { pattern = "%-%-%-+",                type = "comment" },
    { pattern = "%*%s+",                  type = "operator" },
    { pattern = { "%*", "[%*\n]", "\\" }, type = "operator" },
    { pattern = { "%_", "[%_\n]", "\\" }, type = "keyword2" },
    { pattern = "#.-\n",                  type = "keyword"  },
    { pattern = "!?%[.-%]%(.-%)",         type = "function" },
    { pattern = "https?://%S+",           type = "function" },
  },
  symbols = { },
}
