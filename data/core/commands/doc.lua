local core = require "core"
local command = require "core.command"
local common = require "core.common"
local config = require "core.config"
local translate = require "core.doc.translate"
local DocView = require "core.docview"


local function dv()
  return core.active_view
end


local function doc()
  return core.active_view.doc
end


local function get_indent_string()
  if config.tab_type == "hard" then
    return "\t"
  end
  return string.rep(" ", config.indent_size)
end


local function insert_at_start_of_selected_lines(text, skip_empty)
  local line1, col1, line2, col2, swap = doc():get_selection(true)
  for line = line1, line2 do
    local line_text = doc().lines[line]
    if (not skip_empty or line_text:find("%S")) then
      doc():insert(line, 1, text)
    end
  end
  doc():set_selection(line1, col1 + #text, line2, col2 + #text, swap)
end


local function remove_from_start_of_selected_lines(text, skip_empty)
  local line1, col1, line2, col2, swap = doc():get_selection(true)
  for line = line1, line2 do
    local line_text = doc().lines[line]
    if  line_text:sub(1, #text) == text
    and (not skip_empty or line_text:find("%S"))
    then
      doc():remove(line, 1, line, #text + 1)
    end
  end
  doc():set_selection(line1, col1 - #text, line2, col2 - #text, swap)
end


local function append_line_if_last_line(line)
  if line >= #doc().lines then
    doc():insert(line, math.huge, "\n")
  end
end


local function save(filename)
  doc():save(filename)
  core.log("Saved \"%s\"", doc().filename)
end


local commands = {
  ["doc:undo"] = function()
    doc():undo()
  end,

  ["doc:redo"] = function()
    doc():redo()
  end,

  ["doc:cut"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
      doc():delete_to(0)
    end
  end,

  ["doc:copy"] = function()
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      system.set_clipboard(text)
    end
  end,

  ["doc:paste"] = function()
    doc():text_input(system.get_clipboard():gsub("\r", ""))
  end,

  ["doc:newline"] = function()
    local line, col = doc():get_selection()
    local indent = doc().lines[line]:match("^[\t ]*")
    if col <= #indent then
      indent = indent:sub(#indent + 2 - col)
    end
    doc():text_input("\n" .. indent)
  end,

  ["doc:newline-below"] = function()
    local line = doc():get_selection()
    local indent = doc().lines[line]:match("^[\t ]*")
    doc():insert(line, math.huge, "\n" .. indent)
    doc():set_selection(line + 1, math.huge)
  end,

  ["doc:newline-above"] = function()
    local line = doc():get_selection()
    local indent = doc().lines[line]:match("^[\t ]*")
    doc():insert(line, 1, indent .. "\n")
    doc():set_selection(line, math.huge)
  end,

  ["doc:delete"] = function()
    local line, col = doc():get_selection()
    if not doc():has_selection() and doc().lines[line]:find("^%s*$", col) then
      doc():remove(line, col, line, math.huge)
    end
    doc():delete_to(translate.next_char)
  end,

  ["doc:backspace"] = function()
    local line, col = doc():get_selection()
    if not doc():has_selection() then
      local text = doc():get_text(line, 1, line, col)
      if #text >= config.indent_size and text:find("^ *$") then
        doc():delete_to(0, -config.indent_size)
        return
      end
    end
    doc():delete_to(translate.previous_char)
  end,

  ["doc:select-all"] = function()
    doc():set_selection(1, 1, math.huge, math.huge)
  end,

  ["doc:select-none"] = function()
    local line, col = doc():get_selection()
    doc():set_selection(line, col)
  end,

  ["doc:select-lines"] = function()
    local line1, _, line2, _, swap = doc():get_selection(true)
    append_line_if_last_line(line2)
    doc():set_selection(line1, 1, line2 + 1, 1, swap)
  end,

  ["doc:select-word"] = function()
    local line1, col1 = doc():get_selection(true)
    local line1, col1 = translate.start_of_word(doc(), line1, col1)
    local line2, col2 = translate.end_of_word(doc(), line1, col1)
    doc():set_selection(line2, col2, line1, col1)
  end,

  ["doc:join-lines"] = function()
    local line1, _, line2 = doc():get_selection(true)
    if line1 == line2 then line2 = line2 + 1 end
    local text = doc():get_text(line1, 1, line2, math.huge)
    text = text:gsub("(.-)\n[\t ]*", function(x)
      return x:find("^%s*$") and x or x .. " "
    end)
    doc():insert(line1, 1, text)
    doc():remove(line1, #text + 1, line2, math.huge)
    if doc():has_selection() then
      doc():set_selection(line1, math.huge)
    end
  end,

  ["doc:indent"] = function()
    local text = get_indent_string()
    if doc():has_selection() then
      insert_at_start_of_selected_lines(text)
    else
      doc():text_input(text)
    end
  end,

  ["doc:unindent"] = function()
    local text = get_indent_string()
    remove_from_start_of_selected_lines(text)
  end,

  ["doc:duplicate-lines"] = function()
    local line1, col1, line2, col2, swap = doc():get_selection(true)
    append_line_if_last_line(line2)
    local text = doc():get_text(line1, 1, line2 + 1, 1)
    doc():insert(line2 + 1, 1, text)
    local n = line2 - line1 + 1
    doc():set_selection(line1 + n, col1, line2 + n, col2, swap)
  end,

  ["doc:delete-lines"] = function()
    local line1, col1, line2 = doc():get_selection(true)
    append_line_if_last_line(line2)
    doc():remove(line1, 1, line2 + 1, 1)
    doc():set_selection(line1, col1)
  end,

  ["doc:move-lines-up"] = function()
    local line1, col1, line2, col2, swap = doc():get_selection(true)
    append_line_if_last_line(line2)
    if line1 > 1 then
      local text = doc().lines[line1 - 1]
      doc():insert(line2 + 1, 1, text)
      doc():remove(line1 - 1, 1, line1, 1)
      doc():set_selection(line1 - 1, col1, line2 - 1, col2, swap)
    end
  end,

  ["doc:move-lines-down"] = function()
    local line1, col1, line2, col2, swap = doc():get_selection(true)
    append_line_if_last_line(line2 + 1)
    if line2 < #doc().lines then
      local text = doc().lines[line2 + 1]
      doc():remove(line2 + 1, 1, line2 + 2, 1)
      doc():insert(line1, 1, text)
      doc():set_selection(line1 + 1, col1, line2 + 1, col2, swap)
    end
  end,

  ["doc:toggle-line-comments"] = function()
    local comment = doc().syntax.comment
    if not comment then return end
    local comment_text = comment .. " "
    local line1, _, line2 = doc():get_selection(true)
    local uncomment = true
    for line = line1, line2 do
      local text = doc().lines[line]
      if text:find("%S") and text:find(comment_text, 1, true) ~= 1 then
        uncomment = false
      end
    end
    if uncomment then
      remove_from_start_of_selected_lines(comment_text, true)
    else
      insert_at_start_of_selected_lines(comment_text, true)
    end
  end,

  ["doc:upper-case"] = function()
    doc():replace(string.upper)
  end,

  ["doc:lower-case"] = function()
    doc():replace(string.lower)
  end,

  ["doc:go-to-line"] = function()
    local dv = dv()

    local items
    local function init_items()
      if items then return end
      items = {}
      local mt = { __tostring = function(x) return x.text end }
      for i, line in ipairs(dv.doc.lines) do
        local item = { text = line:sub(1, -2), line = i, info = "line: " .. i }
        table.insert(items, setmetatable(item, mt))
      end
    end

    core.command_view:enter("Go To Line", function(text, item)
      local line = item and item.line or tonumber(text)
      if not line then
        core.error("Invalid line number or unmatched string")
        return
      end
      dv.doc:set_selection(line, 1  )
      dv:scroll_to_line(line, true)

    end, function(text)
      if not text:find("^%d*$") then
        init_items()
        return common.fuzzy_match(items, text)
      end
    end)
  end,

  ["doc:toggle-line-ending"] = function()
    doc().crlf = not doc().crlf
  end,

  ["doc:save-as"] = function()
    if doc().filename then
      core.command_view:set_text(doc().filename)
    end
    core.command_view:enter("Save As", function(filename)
      save(filename)
    end, common.path_suggest)
  end,

  ["doc:save"] = function()
    if doc().filename then
      save()
    else
      command.perform("doc:save-as")
    end
  end,

  ["doc:rename"] = function()
    local old_filename = doc().filename
    if not old_filename then
      core.error("Cannot rename unsaved doc")
      return
    end
    core.command_view:set_text(old_filename)
    core.command_view:enter("Rename", function(filename)
      doc():save(filename)
      core.log("Renamed \"%s\" to \"%s\"", old_filename, filename)
      if filename ~= old_filename then
        os.remove(old_filename)
      end
    end, common.path_suggest)
  end,
}


local translations = {
  ["previous-char"] = translate.previous_char,
  ["next-char"] = translate.next_char,
  ["previous-word-start"] = translate.previous_word_start,
  ["next-word-end"] = translate.next_word_end,
  ["previous-block-start"] = translate.previous_block_start,
  ["next-block-end"] = translate.next_block_end,
  ["start-of-doc"] = translate.start_of_doc,
  ["end-of-doc"] = translate.end_of_doc,
  ["start-of-line"] = translate.start_of_line,
  ["end-of-line"] = translate.end_of_line,
  ["start-of-word"] = translate.start_of_word,
  ["end-of-word"] = translate.end_of_word,
  ["previous-line"] = DocView.translate.previous_line,
  ["next-line"] = DocView.translate.next_line,
  ["previous-page"] = DocView.translate.previous_page,
  ["next-page"] = DocView.translate.next_page,
}

for name, fn in pairs(translations) do
  commands["doc:move-to-" .. name] = function() doc():move_to(fn, dv()) end
  commands["doc:select-to-" .. name] = function() doc():select_to(fn, dv()) end
  commands["doc:delete-to-" .. name] = function() doc():delete_to(fn, dv()) end
end

commands["doc:move-to-previous-char"] = function()
  if doc():has_selection() then
    local line, col = doc():get_selection(true)
    doc():set_selection(line, col)
  else
    doc():move_to(translate.previous_char)
  end
end

commands["doc:move-to-next-char"] = function()
  if doc():has_selection() then
    local _, _, line, col = doc():get_selection(true)
    doc():set_selection(line, col)
  else
    doc():move_to(translate.next_char)
  end
end

command.add("core.docview", commands)
