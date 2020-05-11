local core = require "core"
local common = require "core.common"
local config = require "core.config"
local command = require "core.command"
local style = require "core.style"
local keymap = require "core.keymap"
local translate = require "core.doc.translate"
local RootView = require "core.rootview"
local DocView = require "core.docview"

config.autocomplete_max_suggestions = 6

local autocomplete = {}
autocomplete.map = {}


local mt = { __tostring = function(t) return t.text end }

function autocomplete.add(t)
  local items = {}
  for text, info in pairs(t.items) do
    info = (type(info) == "string") and info
    table.insert(items, setmetatable({ text = text, info = info }, mt))
  end
  autocomplete.map[t.name] =  { files = t.files or ".*", items = items }
end


core.add_thread(function()
  local cache = setmetatable({}, { __mode = "k" })

  local function get_symbols(doc)
    local i = 1
    local s = {}
    while i < #doc.lines do
      for sym in doc.lines[i]:gmatch(config.symbol_pattern) do
        s[sym] = true
      end
      i = i + 1
      if i % 100 == 0 then coroutine.yield() end
    end
    return s
  end

  local function cache_is_valid(doc)
    local c = cache[doc]
    return c and c.last_change_id == doc:get_change_id()
  end

  while true do
    local symbols = {}

    -- lift all symbols from all docs
    for _, doc in ipairs(core.docs) do
      -- update the cache if the doc has changed since the last iteration
      if not cache_is_valid(doc) then
        cache[doc] = {
          last_change_id = doc:get_change_id(),
          symbols = get_symbols(doc)
        }
      end
      -- update symbol set with doc's symbol set
      for sym in pairs(cache[doc].symbols) do
        symbols[sym] = true
      end
      coroutine.yield()
    end

    -- update symbols list
    autocomplete.add { name = "open-docs", items = symbols }

    -- wait for next scan
    local valid = true
    while valid do
      coroutine.yield(1)
      for _, doc in ipairs(core.docs) do
        if not cache_is_valid(doc) then
          valid = false
        end
      end
    end

  end
end)


local partial = ""
local suggestions_idx = 1
local suggestions = {}
local last_line, last_col


local function reset_suggestions()
  suggestions_idx = 1
  suggestions = {}
end


local function update_suggestions()
  local doc = core.active_view.doc
  local filename = doc and doc.filename or ""

  -- get all relevant suggestions for given filename
  local items = {}
  for _, v in pairs(autocomplete.map) do
    if common.match_pattern(filename, v.files) then
      for _, item in pairs(v.items) do
        table.insert(items, item)
      end
    end
  end

  -- fuzzy match, remove duplicates and store
  items = common.fuzzy_match(items, partial)
  local j = 1
  for i = 1, config.autocomplete_max_suggestions do
    suggestions[i] = items[j]
    while items[j] and items[i].text == items[j].text do
      items[i].info = items[i].info or items[j].info
      j = j + 1
    end
  end
end


local function get_partial_symbol()
  local doc = core.active_view.doc
  local line2, col2 = doc:get_selection()
  local line1, col1 = doc:position_offset(line2, col2, translate.start_of_word)
  return doc:get_text(line1, col1, line2, col2)
end


local function get_active_view()
  if getmetatable(core.active_view) == DocView then
    return core.active_view
  end
end


local function get_suggestions_rect(av)
  if #suggestions == 0 then
    return 0, 0, 0, 0
  end

  local line, col = av.doc:get_selection()
  local x, y = av:get_line_screen_position(line)
  x = x + av:get_col_x_offset(line, col - #partial)
  y = y + av:get_line_height() + style.padding.y
  local font = av:get_font()
  local th = font:get_height()

  local max_width = 0
  for _, s in ipairs(suggestions) do
    local w = font:get_width(s.text)
    if s.info then
      w = w + style.font:get_width(s.info) + style.padding.x
    end
    max_width = math.max(max_width, w)
  end

  return
    x - style.padding.x,
    y - style.padding.y,
    max_width + style.padding.x * 2,
    #suggestions * (th + style.padding.y) + style.padding.y
end


local function draw_suggestions_box(av)
  -- draw background rect
  local rx, ry, rw, rh = get_suggestions_rect(av)
  renderer.draw_rect(rx, ry, rw, rh, style.background3)

  -- draw text
  local font = av:get_font()
  local lh = font:get_height() + style.padding.y
  local y = ry + style.padding.y / 2
  for i, s in ipairs(suggestions) do
    local color = (i == suggestions_idx) and style.accent or style.text
    common.draw_text(font, color, s.text, "left", rx + style.padding.x, y, rw, lh)
    if s.info then
      color = (i == suggestions_idx) and style.text or style.dim
      common.draw_text(style.font, color, s.info, "right", rx, y, rw - style.padding.x, lh)
    end
    y = y + lh
  end
end


-- patch event logic into RootView
local on_text_input = RootView.on_text_input
local update = RootView.update
local draw = RootView.draw


RootView.on_text_input = function(...)
  on_text_input(...)

  local av = get_active_view()
  if av then
    -- update partial symbol and suggestions
    partial = get_partial_symbol()
    if #partial >= 3 then
      update_suggestions()
      last_line, last_col = av.doc:get_selection()
    else
      reset_suggestions()
    end

    -- scroll if rect is out of bounds of view
    local _, y, _, h = get_suggestions_rect(av)
    local limit = av.position.y + av.size.y
    if y + h > limit then
      av.scroll.to.y = av.scroll.y + y + h - limit
    end
  end
end


RootView.update = function(...)
  update(...)

  local av = get_active_view()
  if av then
    -- reset suggestions if caret was moved
    local line, col = av.doc:get_selection()
    if line ~= last_line or col ~= last_col then
      reset_suggestions()
    end
  end
end


RootView.draw = function(...)
  draw(...)

  local av = get_active_view()
  if av then
    -- draw suggestions box after everything else
    core.root_view:defer_draw(draw_suggestions_box, av)
  end
end


local function predicate()
  return get_active_view() and #suggestions > 0
end


command.add(predicate, {
  ["autocomplete:complete"] = function()
    local doc = core.active_view.doc
    local line, col = doc:get_selection()
    local text = suggestions[suggestions_idx].text
    doc:insert(line, col, text)
    doc:remove(line, col, line, col - #partial)
    doc:set_selection(line, col + #text - #partial)
    reset_suggestions()
  end,

  ["autocomplete:previous"] = function()
    suggestions_idx = math.max(suggestions_idx - 1, 1)
  end,

  ["autocomplete:next"] = function()
    suggestions_idx = math.min(suggestions_idx + 1, #suggestions)
  end,

  ["autocomplete:cancel"] = function()
    reset_suggestions()
  end,
})


keymap.add {
  ["tab"]    = "autocomplete:complete",
  ["up"]     = "autocomplete:previous",
  ["down"]   = "autocomplete:next",
  ["escape"] = "autocomplete:cancel",
}


return autocomplete
