local core = require "core"
local common = require "core.common"
local config = require "core.config"
local style = require "core.style"
local DocView = require "core.docview"
local View = require "core.view"


local StatusView = View:extend()

local separator  = "      "
local separator2 = "   |   "


function StatusView:new()
  StatusView.super.new(self)
  self.focusable = false
  self.message_timeout = 0
  self.message = {}
end


function StatusView:show_message(icon, icon_color, text)
  self.message = {
    icon_color, style.icon_font, icon,
    style.dim, style.font, separator2, style.text, text
  }
  self.message_timeout = system.get_time() + config.message_timeout
end


function StatusView:update()
  self.size.y = style.font:get_height() + style.padding.y * 2

  if system.get_time() < self.message_timeout then
    self.scroll.to.y = self.size.y
  else
    self.scroll.to.y = 0
  end

  StatusView.super.update(self)
end


function StatusView:draw_items(items, right_align, yoffset)
  local font = style.font
  local color = style.text
  local x, y = self:get_content_offset()
  y = y + (yoffset or 0)

  local i
  if right_align then
    x = x + self.size.x - style.padding.x
    i = #items
  else
    x = x + style.padding.x
    i = 1
  end

  while items[i] do
    local item = items[i]

    if type(item) == "userdata" then
      font = item
    elseif type(item) == "table" then
      color = item
    else
      if right_align then
        x = x - font:get_width(item)
        common.draw_text(font, color, item, nil, x, y, 0, self.size.y)
      else
        x = common.draw_text(font, color, item, nil, x, y, 0, self.size.y)
      end
    end

    i = i + (right_align and -1 or 1)
  end
end


local function draw_for_doc_view(self, x, y)
  local dv = core.active_view
  local line, col = dv.doc:get_selection()
  local dirty = dv.doc:is_dirty()

  self:draw_items {
    dirty and style.accent or style.text, style.icon_font, "f",
    style.dim, style.font, separator2, style.text,
    dv.doc.filename and style.text or style.dim, dv.doc:get_name(),
    style.text,
    separator,
    "line: ", line,
    separator,
    col > config.line_limit and style.accent or style.text, "col: ", col,
    style.text,
    separator,
    string.format("%d%%", line / #dv.doc.lines * 100),
  }

  self:draw_items({
    "g", style.icon_font,
    style.text, separator2, style.dim, style.font,
    #dv.doc.lines, " lines",
    separator,
    dv.doc.crlf and "CRLF" or "LF"
  }, true)
end


function StatusView:draw()
  self:draw_background(style.background2)

  if self.message then
    self:draw_items(self.message, false, self.size.y)
  end

  if getmetatable(core.active_view) == DocView then
    draw_for_doc_view(self)
  else
    self:draw_items({
      "g", style.icon_font,
      style.text, separator2, style.dim, style.font,
      #core.docs, " / ", style.dim,
      #core.project_files, " files"
    }, true)
  end
end


return StatusView
