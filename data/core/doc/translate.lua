local common = require "core.common"
local config = require "core.config"

-- functions for translating a Doc position to another position these functions
-- can be passed to Doc:move_to|select_to|delete_to()

local translate = {}


local function is_non_word(char)
  return config.non_word_chars:find(char, nil, true)
end


function translate.previous_char(doc, line, col)
  repeat
    line, col = doc:position_offset(line, col, -1)
  until not common.is_utf8_cont(doc:get_char(line, col))
  return line, col
end


function translate.next_char(doc, line, col)
  repeat
    line, col = doc:position_offset(line, col, 1)
  until not common.is_utf8_cont(doc:get_char(line, col))
  return line, col
end


function translate.previous_word_boundary(doc, line, col)
  local char = doc:get_char(doc:position_offset(line, col, -1))
  local inword = not is_non_word(char)
  repeat
    local line2, col2 = line, col
    line, col = doc:position_offset(line, col, -1)
    if line == line2 and col == col2 then
      break
    end
    local c = doc:get_char(doc:position_offset(line, col, -1))
  until inword and is_non_word(c) or not inword and c ~= char
  return line, col
end


function translate.next_word_boundary(doc, line, col)
  local char = doc:get_char(line, col)
  local inword = not is_non_word(char)
  repeat
    local line2, col2 = line, col
    line, col = doc:position_offset(line, col, 1)
    if line == line2 and col == col2 then
      break
    end
    local c = doc:get_char(line, col)
  until inword and is_non_word(c) or not inword and c ~= char
  return line, col
end


function translate.start_of_word(doc, line, col)
  while true do
    local line2, col2 = doc:position_offset(line, col, -1)
    local char = doc:get_char(line2, col2)
    if is_non_word(char)
    or line == line2 and col == col2 then
      break
    end
    line, col = line2, col2
  end
  return line, col
end


function translate.end_of_word(doc, line, col)
  while true do
    local line2, col2 = doc:position_offset(line, col, 1)
    local char = doc:get_char(line, col)
    if is_non_word(char)
    or line == line2 and col == col2 then
      break
    end
    line, col = line2, col2
  end
  return line, col
end


function translate.previous_start_of_block(doc, line, col)
  while true do
    line = line - 1
    if line <= 1 then
      return 1, 1
    end
    if doc.lines[line-1]:match("^%s*$")
    and not doc.lines[line]:match("^%s*$") then
      return line, (doc.lines[line]:find("%S"))
    end
  end
end


function translate.next_start_of_block(doc, line, col)
  while true do
    line = line + 1
    if line >= #doc.lines then
      return #doc.lines, 1
    end
    if doc.lines[line-1]:match("^%s*$")
    and not doc.lines[line]:match("^%s*$") then
      return line, (doc.lines[line]:find("%S"))
    end
  end
end


function translate.start_of_line(doc, line, col)
  return line, 1
end


function translate.end_of_line(doc, line, col)
  return line, math.huge
end


function translate.start_of_doc(doc, line, col)
  return 1, 1
end


function translate.end_of_doc(doc, line, col)
  return #doc.lines, #doc.lines[#doc.lines]
end


return translate
