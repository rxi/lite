local core = require "core"

local no_errors = true
local files = system.list_dir(EXEDIR .. "/data/plugins/language")
for _, filename in ipairs(files) do
  local langname =  filename:gsub(".lua$", "")
  if langname ~= "init" then
    local ok = core.try(require, "plugins.language." .. langname)
    if ok then
      core.log_quiet("Loaded language %q", langname)
    else
      no_errors = false
    end
  end
end
return no_errors
