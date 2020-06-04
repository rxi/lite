local core = require "core"
local command = require "core.command"
local config = require "core.config"
local search = require "core.doc.search"
local DocView = require "core.docview"

local max_previous_finds = 50


local function doc()
  return core.active_view.doc
end


local previous_finds
local last_doc
local last_fn, last_text


local function push_previous_find(doc, sel)
  if last_doc ~= doc then
    last_doc = doc
    previous_finds = {}
  end
  if #previous_finds >= max_previous_finds then
    table.remove(previous_finds, 1)
  end
  table.insert(previous_finds, sel or { doc:get_selection() })
end


local function find(label, search_fn)
  local dv = core.active_view
  local sel = { dv.doc:get_selection() }
  local text = dv.doc:get_text(table.unpack(sel))
  local found = false

  core.command_view:set_text(text, true)

  core.command_view:enter(label, function(text)
    if found then
      last_fn, last_text = search_fn, text
      previous_finds = {}
      push_previous_find(dv.doc, sel)
    else
      core.error("Couldn't find %q", text)
      dv.doc:set_selection(table.unpack(sel))
      dv:scroll_to_make_visible(sel[1], sel[2])
    end

  end, function(text)
    local ok, line1, col1, line2, col2 = pcall(search_fn, dv.doc, sel[1], sel[2], text)
    if ok and line1 and text ~= "" then
      dv.doc:set_selection(line2, col2, line1, col1)
      dv:scroll_to_line(line2, true)
      found = true
    else
      dv.doc:set_selection(table.unpack(sel))
      found = false
    end

  end, function(explicit)
    if explicit then
      dv.doc:set_selection(table.unpack(sel))
      dv:scroll_to_make_visible(sel[1], sel[2])
    end
  end)
end


local function replace(kind, default, fn)
  core.command_view:set_text(default, true)

  core.command_view:enter("Find To Replace " .. kind, function(old)
    core.command_view:set_text(old, true)

    local s = string.format("Replace %s %q With", kind, old)
    core.command_view:enter(s, function(new)
      local n = doc():replace(function(text)
        return fn(text, old, new)
      end)
      core.log("Replaced %d instance(s) of %s %q with %q", n, kind, old, new)
    end)
  end)
end


local function has_selection()
  return core.active_view:is(DocView)
     and core.active_view.doc:has_selection()
end

command.add(has_selection, {
  ["find-replace:select-next"] = function()
    local l1, c1, l2, c2 = doc():get_selection(true)
    local text = doc():get_text(l1, c1, l2, c2)
    local l1, c1, l2, c2 = search.find(doc(), l2, c2, text, { wrap = true })
    if l2 then doc():set_selection(l2, c2, l1, c1) end
  end
})

command.add("core.docview", {
  ["find-replace:find"] = function()
    find("Find Text", function(doc, line, col, text)
      local opt = { wrap = true, no_case = true }
      return search.find(doc, line, col, text, opt)
    end)
  end,

  ["find-replace:find-pattern"] = function()
    find("Find Text Pattern", function(doc, line, col, text)
      local opt = { wrap = true, no_case = true, pattern = true }
      return search.find(doc, line, col, text, opt)
    end)
  end,

  ["find-replace:repeat-find"] = function()
    if not last_fn then
      core.error("No find to continue from")
    else
      local line, col = doc():get_selection()
      local line1, col1, line2, col2 = last_fn(doc(), line, col, last_text)
      if line1 then
        push_previous_find(doc())
        doc():set_selection(line2, col2, line1, col1)
        core.active_view:scroll_to_line(line2, true)
      end
    end
  end,

  ["find-replace:previous-find"] = function()
    local sel = table.remove(previous_finds)
    if not sel or doc() ~= last_doc then
      core.error("No previous finds")
      return
    end
    doc():set_selection(table.unpack(sel))
    core.active_view:scroll_to_line(sel[3], true)
  end,

  ["find-replace:replace"] = function()
    replace("Text", "", function(text, old, new)
      return text:gsub(old:gsub("%W", "%%%1"), new:gsub("%%", "%%%%"), nil)
    end)
  end,

  ["find-replace:replace-pattern"] = function()
    replace("Pattern", "", function(text, old, new)
      return text:gsub(old, new)
    end)
  end,

  ["find-replace:replace-symbol"] = function()
    local first = ""
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      first = text:match(config.symbol_pattern) or ""
    end
    replace("Symbol", first, function(text, old, new)
      local n = 0
      local res = text:gsub(config.symbol_pattern, function(sym)
        if old == sym then
          n = n + 1
          return new
        end
      end)
      return res, n
    end)
  end,
})
