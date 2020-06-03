local core = require "core"
local common = require "core.common"
local command = require "core.command"
local keymap = require "core.keymap"
local LogView = require "core.logview"


local fullscreen = false

command.add(nil, {
  ["core:quit"] = function()
    core.quit()
  end,

  ["core:force-quit"] = function()
    core.quit(true)
  end,

  ["core:toggle-fullscreen"] = function()
    fullscreen = not fullscreen
    system.set_window_mode(fullscreen and "fullscreen" or "normal")
  end,

  ["core:reload-module"] = function()
    core.command_view:enter("Reload Module", function(text, item)
      local text = item and item.text or text
      core.reload_module(text)
      core.log("Reloaded module %q", text)
    end, function(text)
      local items = {}
      for name in pairs(package.loaded) do
        table.insert(items, name)
      end
      return common.fuzzy_match(items, text)
    end)
  end,

  ["core:find-command"] = function()
    local commands = command.get_all_valid()
    core.command_view:enter("Do Command", function(text, item)
      if item then
        command.perform(item.command)
      end
    end, function(text)
      local res = common.fuzzy_match(commands, text)
      for i, name in ipairs(res) do
        res[i] = {
          text = command.prettify_name(name),
          info = keymap.get_binding(name),
          command = name,
        }
      end
      return res
    end)
  end,

  ["core:find-file"] = function()
    core.command_view:enter("Open File From Project", function(text, item)
      text = item and item.text or text
      core.root_view:open_doc(core.open_doc(text))
    end, function(text)
      local files = {}
      for _, item in pairs(core.project_files) do
        if item.type == "file" then
          table.insert(files, item.filename)
        end
      end
      return common.fuzzy_match(files, text)
    end)
  end,

  ["core:new-doc"] = function()
    core.root_view:open_doc(core.open_doc())
  end,

  ["core:open-file"] = function()
    core.command_view:enter("Open File", function(text)
      core.root_view:open_doc(core.open_doc(text))
    end, common.path_suggest)
  end,

  ["core:open-log"] = function()
    local node = core.root_view:get_active_node()
    node:add_view(LogView())
  end,

  ["core:open-user-module"] = function()
    core.root_view:open_doc(core.open_doc(EXEDIR .. "/data/user/init.lua"))
  end,

  ["core:open-project-module"] = function()
    local filename = ".lite_project.lua"
    if system.get_file_info(filename) then
      core.root_view:open_doc(core.open_doc(filename))
    else
      local doc = core.open_doc()
      core.root_view:open_doc(doc)
      doc:save(filename)
    end
  end,
})
