local common = require "core.common"
local style = {}

style.padding = { x = common.round(14 * _SCALE), y = common.round(7 * _SCALE) }
style.divider_size = common.round(1 * _SCALE)
style.scrollbar_size = common.round(4 * _SCALE)
style.caret_width = common.round(2 * _SCALE)
style.tab_width = common.round(170 * _SCALE)

style.font = renderer.font.load(_EXEDIR .. "/data/fonts/font.ttf", 14 * _SCALE)
style.big_font = renderer.font.load(_EXEDIR .. "/data/fonts/font.ttf", 34 * _SCALE)
style.icon_font = renderer.font.load(_EXEDIR .. "/data/fonts/icons.ttf", 14 * _SCALE)
style.code_font = renderer.font.load(_EXEDIR .. "/data/fonts/monospace.ttf", 13.5 * _SCALE)

style.background = { common.color "#1F1F2B" }
style.background2 = { common.color "#181821" }
style.background3 = { common.color "#181821" }
style.text = { common.color "#8989ab" }
style.caret = { common.color "#8585FF" }
style.accent = { common.color "#ccccff" }
style.dim = { common.color "#42425c" }
style.divider = { common.color "#15151C" }
style.selection = { common.color "#39394f" }
style.line_number = { common.color "#42425c" }
style.line_number2 = { common.color "#73739e" }
style.line_highlight = { common.color "#252533" }
style.scrollbar = { common.color "#323245" }
style.scrollbar2 = { common.color "#3b3b52" }
style.whitespace = { common.color "rgba(255, 255, 255, 0.2)" }

style.syntax = {}
style.syntax["normal"] = { common.color "#F5F5F5" }
style.syntax["symbol"] = { common.color "#F5F5F5" }
style.syntax["comment"] = { common.color "#616C76" }
style.syntax["keyword"] = { common.color "#E58AC9" }
style.syntax["keyword2"] = { common.color "#F77483" }
style.syntax["number"] = { common.color "#FFA94D" }
style.syntax["literal"] = { common.color "#FFA94D" }
style.syntax["string"] = { common.color "#F8C34C" }
style.syntax["operator"] = { common.color "#93DDFA" }
style.syntax["function"] = { common.color "#93DDFA" }

return style
