require "core.strict"
local common = require "core.common"
local config = require "core.config"
local style = require "core.style"
local command
local keymap
local RootView
local StatusView
local CommandView
local Doc

local core = {}


local function project_scan_thread()
  local function diff_files(a, b)
    if #a ~= #b then return true end
    for i, v in ipairs(a) do
      if b[i].filename ~= v.filename
      or b[i].modified ~= v.modified then
        return true
      end
    end
  end

  local function compare_file(a, b)
    return a.filename < b.filename
  end

  local function get_files(path, t)
    coroutine.yield()
    t = t or {}
    local size_limit = config.file_size_limit * 10e5
    local all = system.list_dir(path) or {}
    local dirs, files = {}, {}

    for _, file in ipairs(all) do
      if not common.match_pattern(file, config.ignore_files) then
        local file = (path ~= "." and path .. PATHSEP or "") .. file
        local info = system.get_file_info(file)
        if info and info.size < size_limit then
          info.filename = file
          table.insert(info.type == "dir" and dirs or files, info)
        end
      end
    end

    table.sort(dirs, compare_file)
    for _, f in ipairs(dirs) do
      table.insert(t, f)
      get_files(f.filename, t)
    end

    table.sort(files, compare_file)
    for _, f in ipairs(files) do
      table.insert(t, f)
    end

    return t
  end

  while true do
    -- get project files and replace previous table if the new table is
    -- different
    local t = get_files(".")
    if diff_files(core.project_files, t) then
      core.project_files = t
      core.redraw = true
    end

    -- wait for next scan
    coroutine.yield(config.project_scan_rate)
  end
end


function core.init()
  command = require "core.command"
  keymap = require "core.keymap"
  RootView = require "core.rootview"
  StatusView = require "core.statusview"
  CommandView = require "core.commandview"
  Doc = require "core.doc"

  local project_dir = EXEDIR
  local files = {}
  for i = 2, #ARGS do
    local info = system.get_file_info(ARGS[i]) or {}
    if info.type == "file" then
      table.insert(files, system.absolute_path(ARGS[i]))
    elseif info.type == "dir" then
      project_dir = ARGS[i]
    end
  end

  system.chdir(project_dir)

  core.frame_start = 0
  core.clip_rect_stack = {{ 0,0,0,0 }}
  core.log_items = {}
  core.docs = {}
  core.threads = setmetatable({}, { __mode = "k" })
  core.project_files = {}
  core.redraw = true

  core.root_view = RootView()
  core.command_view = CommandView()
  core.status_view = StatusView()

  core.root_view.root_node:split("down", core.command_view, true)
  core.root_view.root_node.b:split("down", core.status_view, true)

  core.add_thread(project_scan_thread)
  command.add_defaults()
  local got_plugin_error = not core.load_plugins()
  local got_user_error = not core.try(require, "user")
  local got_project_error = not core.load_project_module()

  for _, filename in ipairs(files) do
    core.root_view:open_doc(core.open_doc(filename))
  end

  if got_plugin_error or got_user_error or got_project_error then
    command.perform("core:open-log")
  end
end


local temp_uid = (system.get_time() * 1000) % 0xffffffff
local temp_file_prefix = string.format(".lite_temp_%08x", temp_uid)
local temp_file_counter = 0

local function delete_temp_files()
  for _, filename in ipairs(system.list_dir(EXEDIR)) do
    if filename:find(temp_file_prefix, 1, true) == 1 then
      os.remove(EXEDIR .. PATHSEP .. filename)
    end
  end
end

function core.temp_filename(ext)
  temp_file_counter = temp_file_counter + 1
  return EXEDIR .. PATHSEP .. temp_file_prefix
      .. string.format("%06x", temp_file_counter) .. (ext or "")
end


function core.quit(force)
  if force then
    delete_temp_files()
    os.exit()
  end
  local dirty_count = 0
  local dirty_name
  for _, doc in ipairs(core.docs) do
    if doc:is_dirty() then
      dirty_count = dirty_count + 1
      dirty_name = doc:get_name()
    end
  end
  if dirty_count > 0 then
    local text
    if dirty_count == 1 then
      text = string.format("\"%s\" has unsaved changes. Quit anyway?", dirty_name)
    else
      text = string.format("%d docs have unsaved changes. Quit anyway?", dirty_count)
    end
    local confirm = system.show_confirm_dialog("Unsaved Changes", text)
    if not confirm then return end
  end
  core.quit(true)
end


function core.load_plugins()
  local no_errors = true
  local files = system.list_dir(EXEDIR .. "/data/plugins")
  for _, filename in ipairs(files) do
    local modname = "plugins." .. filename:gsub(".lua$", "")
    local ok = core.try(require, modname)
    if ok then
      core.log_quiet("Loaded plugin %q", modname)
    else
      no_errors = false
    end
  end
  return no_errors
end


function core.load_project_module()
  local filename = ".lite_project.lua"
  if system.get_file_info(filename) then
    return core.try(function()
      local fn, err = loadfile(filename)
      if not fn then error("Error when loading project module:\n\t" .. err) end
      fn()
      core.log_quiet("Loaded project module")
    end)
  end
  return true
end


function core.reload_module(name)
  local old = package.loaded[name]
  package.loaded[name] = nil
  local new = require(name)
  if type(old) == "table" then
    for k, v in pairs(new) do old[k] = v end
    package.loaded[name] = old
  end
end


function core.set_active_view(view)
  assert(view, "Tried to set active view to nil")
  if view ~= core.active_view then
    core.last_active_view = core.active_view
    core.active_view = view
  end
end


function core.add_thread(f, weak_ref)
  local key = weak_ref or #core.threads + 1
  local fn = function() return core.try(f) end
  core.threads[key] = { cr = coroutine.create(fn), wake = 0 }
end


function core.push_clip_rect(x, y, w, h)
  local x2, y2, w2, h2 = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  local r, b, r2, b2 = x+w, y+h, x2+w2, y2+h2
  x, y = math.max(x, x2), math.max(y, y2)
  b, r = math.min(b, b2), math.min(r, r2)
  w, h = r-x, b-y
  table.insert(core.clip_rect_stack, { x, y, w, h })
  renderer.set_clip_rect(x, y, w, h)
end


function core.pop_clip_rect()
  table.remove(core.clip_rect_stack)
  local x, y, w, h = table.unpack(core.clip_rect_stack[#core.clip_rect_stack])
  renderer.set_clip_rect(x, y, w, h)
end


function core.open_doc(filename)
  if filename then
    -- try to find existing doc for filename
    local abs_filename = system.absolute_path(filename)
    for _, doc in ipairs(core.docs) do
      if doc.filename
      and abs_filename == system.absolute_path(doc.filename) then
        return doc
      end
    end
  end
  -- no existing doc for filename; create new
  local doc = Doc(filename)
  table.insert(core.docs, doc)
  core.log_quiet(filename and "Opened doc \"%s\"" or "Opened new doc", filename)
  return doc
end


function core.get_views_referencing_doc(doc)
  local res = {}
  local views = core.root_view.root_node:get_children()
  for _, view in ipairs(views) do
    if view.doc == doc then table.insert(res, view) end
  end
  return res
end


local function log(icon, icon_color, fmt, ...)
  local text = string.format(fmt, ...)
  if icon then
    core.status_view:show_message(icon, icon_color, text)
  end

  local info = debug.getinfo(2, "Sl")
  local at = string.format("%s:%d", info.short_src, info.currentline)
  local item = { text = text, time = os.time(), at = at }
  table.insert(core.log_items, item)
  if #core.log_items > config.max_log_items then
    table.remove(core.log_items, 1)
  end
  return item
end


function core.log(...)
  return log("i", style.text, ...)
end


function core.log_quiet(...)
  return log(nil, nil, ...)
end


function core.error(...)
  return log("!", style.accent, ...)
end


function core.try(fn, ...)
  local err
  local ok, res = xpcall(fn, function(msg)
    local item = core.error("%s", msg)
    item.info = debug.traceback(nil, 2):gsub("\t", "")
    err = msg
  end, ...)
  if ok then
    return true, res
  end
  return false, err
end


function core.on_event(type, ...)
  local did_keymap = false
  if type == "textinput" then
    core.root_view:on_text_input(...)
  elseif type == "keypressed" then
    did_keymap = keymap.on_key_pressed(...)
  elseif type == "keyreleased" then
    keymap.on_key_released(...)
  elseif type == "mousemoved" then
    core.root_view:on_mouse_moved(...)
  elseif type == "mousepressed" then
    core.root_view:on_mouse_pressed(...)
  elseif type == "mousereleased" then
    core.root_view:on_mouse_released(...)
  elseif type == "mousewheel" then
    core.root_view:on_mouse_wheel(...)
  elseif type == "filedropped" then
    local filename, mx, my = ...
    local info = system.get_file_info(filename)
    if info and info.type == "dir" then
      system.exec(string.format("%q %q", EXEFILE, filename))
    else
      local ok, doc = core.try(core.open_doc, filename)
      if ok then
        local node = core.root_view.root_node:get_child_overlapping_point(mx, my)
        node:set_active_view(node.active_view)
        core.root_view:open_doc(doc)
      end
    end
  elseif type == "quit" then
    core.quit()
  end
  return did_keymap
end


function core.step()
  -- handle events
  local did_keymap = false
  local mouse_moved = false
  local mouse = { x = 0, y = 0, dx = 0, dy = 0 }

  for type, a,b,c,d in system.poll_event do
    if type == "mousemoved" then
      mouse_moved = true
      mouse.x, mouse.y = a, b
      mouse.dx, mouse.dy = mouse.dx + c, mouse.dy + d
    elseif type == "textinput" and did_keymap then
      did_keymap = false
    else
      local _, res = core.try(core.on_event, type, a, b, c, d)
      did_keymap = res or did_keymap
    end
    core.redraw = true
  end
  if mouse_moved then
    core.try(core.on_event, "mousemoved", mouse.x, mouse.y, mouse.dx, mouse.dy)
  end

  local width, height = renderer.get_size()

  -- update
  core.root_view.size.x, core.root_view.size.y = width, height
  core.root_view:update()
  if not core.redraw then return false end
  core.redraw = false

  -- close unreferenced docs
  for i = #core.docs, 1, -1 do
    local doc = core.docs[i]
    if #core.get_views_referencing_doc(doc) == 0 then
      table.remove(core.docs, i)
      core.log_quiet("Closed doc \"%s\"", doc:get_name())
    end
  end

  -- update window title
  local name = core.active_view:get_name()
  local title = (name ~= "---") and (name .. " - lite") or  "lite"
  if title ~= core.window_title then
    system.set_window_title(title)
    core.window_title = title
  end

  -- draw
  renderer.begin_frame()
  core.clip_rect_stack[1] = { 0, 0, width, height }
  renderer.set_clip_rect(table.unpack(core.clip_rect_stack[1]))
  core.root_view:draw()
  renderer.end_frame()
  return true
end


local run_threads = coroutine.wrap(function()
  while true do
    local max_time = 1 / config.fps - 0.004
    local ran_any_threads = false

    for k, thread in pairs(core.threads) do
      -- run thread
      if thread.wake < system.get_time() then
        local _, wait = assert(coroutine.resume(thread.cr))
        if coroutine.status(thread.cr) == "dead" then
          if type(k) == "number" then
            table.remove(core.threads, k)
          else
            core.threads[k] = nil
          end
        elseif wait then
          thread.wake = system.get_time() + wait
        end
        ran_any_threads = true
      end

      -- stop running threads if we're about to hit the end of frame
      if system.get_time() - core.frame_start > max_time then
        coroutine.yield()
      end
    end

    if not ran_any_threads then coroutine.yield() end
  end
end)


function core.run()
  while true do
    core.frame_start = system.get_time()
    local did_redraw = core.step()
    run_threads()
    if not did_redraw and not system.window_has_focus() then
      system.wait_event(0.25)
    end
    local elapsed = system.get_time() - core.frame_start
    system.sleep(math.max(0, 1 / config.fps - elapsed))
  end
end


function core.on_error(err)
  -- write error to file
  local fp = io.open(EXEDIR .. "/error.txt", "wb")
  fp:write("Error: " .. tostring(err) .. "\n")
  fp:write(debug.traceback(nil, 4))
  fp:close()
  -- save copy of all unsaved documents
  for _, doc in ipairs(core.docs) do
    if doc:is_dirty() and doc.filename then
      doc:save(doc.filename .. "~")
    end
  end
end


return core
