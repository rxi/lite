local DocView = require "core.docview"
local keymap = require "core.keymap"


local on_mouse_pressed = DocView.on_mouse_pressed
DocView.on_mouse_pressed = function(self, button, x, y, clicks)
  local old_line, old_col = self.doc:get_selection(true)
  on_mouse_pressed(self, button, x, y, clicks)
  if (keymap.modkeys["shift"] and button == "left") then
    local new_line, new_col = self.doc:get_selection(true)
    self.doc:set_selection(new_line, new_col, old_line, old_col)
  end
end
