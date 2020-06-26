local core = require "core"
local common = require "core.common"
local config = require "core.config"
local style = require "core.style"
local keymap = require "core.keymap"
local translate = require "core.doc.translate"
local View = require "core.view"


local DocView = View:extend()


local function move_to_line_offset(dv, line, col, offset)
  local xo = dv.last_x_offset
  if xo.line ~= line or xo.col ~= col then
    xo.offset = dv:get_col_x_offset(line, col)
  end
  xo.line = line + offset
  xo.col = dv:get_x_offset_col(line + offset, xo.offset)
  return xo.line, xo.col
end


DocView.translate = {
  ["previous_page"] = function(doc, line, col, dv)
    local min, max = dv:get_visible_line_range()
    return line - (max - min), 1
  end,

  ["next_page"] = function(doc, line, col, dv)
    local min, max = dv:get_visible_line_range()
    return line + (max - min), 1
  end,

  ["previous_line"] = function(doc, line, col, dv)
    if line == 1 then
      return 1, 1
    end
    return move_to_line_offset(dv, line, col, -1)
  end,

  ["next_line"] = function(doc, line, col, dv)
    if line == #doc.lines then
      return #doc.lines, math.huge
    end
    return move_to_line_offset(dv, line, col, 1)
  end,
}

local blink_period = 0.8


function DocView:new(doc)
  DocView.super.new(self)
  self.cursor = "ibeam"
  self.scrollable = true
  self.doc = assert(doc)
  self.font = "code_font"
  self.last_x_offset = {}
  self.blink_timer = 0
end


function DocView:try_close(do_close)
  if self.doc:is_dirty()
  and #core.get_views_referencing_doc(self.doc) == 1 then
    core.command_view:enter("Unsaved Changes; Confirm Close", function(_, item)
      if item.text:match("^[cC]") then
        do_close()
      elseif item.text:match("^[sS]") then
        self.doc:save()
        do_close()
      end
    end, function(text)
      local items = {}
      if not text:find("^[^cC]") then table.insert(items, "Close Without Saving") end
      if not text:find("^[^sS]") then table.insert(items, "Save And Close") end
      return items
    end)
  else
    do_close()
  end
end


function DocView:get_name()
  local post = self.doc:is_dirty() and "*" or ""
  local name = self.doc:get_name()
  return name:match("[^/%\\]*$") .. post
end


function DocView:get_scrollable_size()
  return self:get_line_height() * (#self.doc.lines - 1) + self.size.y
end


function DocView:get_font()
  return style[self.font]
end


function DocView:get_line_height()
  return math.floor(self:get_font():get_height() * config.line_height)
end


function DocView:get_gutter_width()
  return self:get_font():get_width(#self.doc.lines) + style.padding.x * 2
end


function DocView:get_line_screen_position(idx)
  local x, y = self:get_content_offset()
  local lh = self:get_line_height()
  local gw = self:get_gutter_width()
  return x + gw, y + (idx-1) * lh + style.padding.y
end


function DocView:get_line_text_y_offset()
  local lh = self:get_line_height()
  local th = self:get_font():get_height()
  return (lh - th) / 2
end


function DocView:get_visible_line_range()
  local x, y, x2, y2 = self:get_content_bounds()
  local lh = self:get_line_height()
  local minline = math.max(1, math.floor(y / lh))
  local maxline = math.min(#self.doc.lines, math.floor(y2 / lh) + 1)
  return minline, maxline
end


function DocView:get_col_x_offset(line, col)
  local text = self.doc.lines[line]
  if not text then return 0 end
  return self:get_font():get_width(text:sub(1, col - 1))
end


function DocView:get_x_offset_col(line, x)
  local text = self.doc.lines[line]

  local xoffset, last_i, i = 0, 1, 1
  for char in common.utf8_chars(text) do
    local w = self:get_font():get_width(char)
    if xoffset >= x then
      return (xoffset - x > w / 2) and last_i or i
    end
    xoffset = xoffset + w
    last_i = i
    i = i + #char
  end

  return #text
end


function DocView:resolve_screen_position(x, y)
  local ox, oy = self:get_line_screen_position(1)
  local line = math.floor((y - oy) / self:get_line_height()) + 1
  line = common.clamp(line, 1, #self.doc.lines)
  local col = self:get_x_offset_col(line, x - ox)
  return line, col
end


function DocView:scroll_to_line(line, ignore_if_visible, instant)
  local min, max = self:get_visible_line_range()
  if not (ignore_if_visible and line > min and line < max) then
    local lh = self:get_line_height()
    self.scroll.to.y = math.max(0, lh * (line - 1) - self.size.y / 2)
    if instant then
      self.scroll.y = self.scroll.to.y
    end
  end
end


function DocView:scroll_to_make_visible(line, col)
  local min = self:get_line_height() * (line - 1)
  local max = self:get_line_height() * (line + 2) - self.size.y
  self.scroll.to.y = math.min(self.scroll.to.y, min)
  self.scroll.to.y = math.max(self.scroll.to.y, max)
  local gw = self:get_gutter_width()
  local xoffset = self:get_col_x_offset(line, col)
  local max = xoffset - self.size.x + gw + self.size.x / 5
  self.scroll.to.x = math.max(0, max)
end


local function mouse_selection(doc, clicks, line1, col1, line2, col2)
  local swap = line2 < line1 or line2 == line1 and col2 <= col1
  if swap then
    line1, col1, line2, col2 = line2, col2, line1, col1
  end
  if clicks == 2 then
    line1, col1 = translate.start_of_word(doc, line1, col1)
    line2, col2 = translate.end_of_word(doc, line2, col2)
  elseif clicks == 3 then
    if line2 == #doc.lines and doc.lines[#doc.lines] ~= "\n" then
      doc:insert(math.huge, math.huge, "\n")
    end
    line1, col1, line2, col2 = line1, 1, line2 + 1, 1
  end
  if swap then
    return line2, col2, line1, col1
  end
  return line1, col1, line2, col2
end


function DocView:on_mouse_pressed(button, x, y, clicks)
  local caught = DocView.super.on_mouse_pressed(self, button, x, y, clicks)
  if caught then
    return
  end
  if keymap.modkeys["shift"] then
    if clicks == 1 then
      local line1, col1 = select(3, self.doc:get_selection())
      local line2, col2 = self:resolve_screen_position(x, y)
      self.doc:set_selection(line2, col2, line1, col1)
    end
  else
    local line, col = self:resolve_screen_position(x, y)
    self.doc:set_selection(mouse_selection(self.doc, clicks, line, col, line, col))
    self.mouse_selecting = { line, col, clicks = clicks }
  end
  self.blink_timer = 0
end


function DocView:on_mouse_moved(x, y, ...)
  DocView.super.on_mouse_moved(self, x, y, ...)

  if self:scrollbar_overlaps_point(x, y) or self.dragging_scrollbar then
    self.cursor = "arrow"
  else
    self.cursor = "ibeam"
  end

  if self.mouse_selecting then
    local l1, c1 = self:resolve_screen_position(x, y)
    local l2, c2 = table.unpack(self.mouse_selecting)
    local clicks = self.mouse_selecting.clicks
    self.doc:set_selection(mouse_selection(self.doc, clicks, l1, c1, l2, c2))
  end
end


function DocView:on_mouse_released(button)
  DocView.super.on_mouse_released(self, button)
  self.mouse_selecting = nil
end


function DocView:on_text_input(text)
  self.doc:text_input(text)
end


function DocView:update()
  -- scroll to make caret visible and reset blink timer if it moved
  local line, col = self.doc:get_selection()
  if (line ~= self.last_line or col ~= self.last_col) and self.size.x > 0 then
    if core.active_view == self then
      self:scroll_to_make_visible(line, col)
    end
    self.blink_timer = 0
    self.last_line, self.last_col = line, col
  end

  -- update blink timer
  if self == core.active_view and not self.mouse_selecting then
    local n = blink_period / 2
    local prev = self.blink_timer
    self.blink_timer = (self.blink_timer + 1 / config.fps) % blink_period
    if (self.blink_timer > n) ~= (prev > n) then
      core.redraw = true
    end
  end

  DocView.super.update(self)
end


function DocView:draw_line_highlight(x, y)
  local lh = self:get_line_height()
  renderer.draw_rect(x, y, self.size.x, lh, style.line_highlight)
end


function DocView:draw_line_text(idx, x, y)
  local tx, ty = x, y + self:get_line_text_y_offset()
  local font = self:get_font()
  for _, type, text in self.doc.highlighter:each_token(idx) do
    local color = style.syntax[type]
    tx = renderer.draw_text(font, text, tx, ty, color)
  end
end


function DocView:draw_line_body(idx, x, y)
  local line, col = self.doc:get_selection()

  -- draw selection if it overlaps this line
  local line1, col1, line2, col2 = self.doc:get_selection(true)
  if idx >= line1 and idx <= line2 then
    local text = self.doc.lines[idx]
    if line1 ~= idx then col1 = 1 end
    if line2 ~= idx then col2 = #text + 1 end
    local x1 = x + self:get_col_x_offset(idx, col1)
    local x2 = x + self:get_col_x_offset(idx, col2)
    local lh = self:get_line_height()
    renderer.draw_rect(x1, y, x2 - x1, lh, style.selection)
  end

  -- draw line highlight if caret is on this line
  if config.highlight_current_line and not self.doc:has_selection()
  and line == idx and core.active_view == self then
    self:draw_line_highlight(x + self.scroll.x, y)
  end

  -- draw line's text
  self:draw_line_text(idx, x, y)

  -- draw caret if it overlaps this line
  if line == idx and core.active_view == self
  and self.blink_timer < blink_period / 2
  and system.window_has_focus() then
    local lh = self:get_line_height()
    local x1 = x + self:get_col_x_offset(line, col)
    renderer.draw_rect(x1, y, style.caret_width, lh, style.caret)
  end
end


function DocView:draw_line_gutter(idx, x, y)
  local color = style.line_number
  local line1, _, line2, _ = self.doc:get_selection(true)
  if idx >= line1 and idx <= line2 then
    color = style.line_number2
  end
  local yoffset = self:get_line_text_y_offset()
  x = x + style.padding.x
  renderer.draw_text(self:get_font(), idx, x, y + yoffset, color)
end


function DocView:draw()
  self:draw_background(style.background)

  local font = self:get_font()
  font:set_tab_width(font:get_width(" ") * config.indent_size)

  local minline, maxline = self:get_visible_line_range()
  local lh = self:get_line_height()

  local _, y = self:get_line_screen_position(minline)
  local x = self.position.x
  for i = minline, maxline do
    self:draw_line_gutter(i, x, y)
    y = y + lh
  end

  local x, y = self:get_line_screen_position(minline)
  local gw = self:get_gutter_width()
  local pos = self.position
  core.push_clip_rect(pos.x + gw, pos.y, self.size.x, self.size.y)
  for i = minline, maxline do
    self:draw_line_body(i, x, y)
    y = y + lh
  end
  core.pop_clip_rect()

  self:draw_scrollbar()
end


return DocView
