-- @Name: Glox Settings
-- @Description: Settings program for Glox.
-- @Author: Amanda Cameron

-- Settings program for agui-shell

os.loadAPI("__LIB__/glox/glox")

local app = kidven.new('agui-app')

local settings = kidven.new('glox-settings', app)

local main_window = kidven.new('agui-tab-bar', 1, 1, term.getSize())

-- Functions!

local function new_tab(name)
  local cont = kidven.new('agui-container', 1, 1, main_window.agui_widget.width, main_window.agui_widget.height - 1)

  main_window:add_tab(name, cont)

  return kidven.new('agui-layout', cont)
end

-- General Settings.

local general_settings = new_tab('General')

local computer_id = kidven.new('agui-label', 1, 1, 'ID: ' .. os.getComputerID())

general_settings:add(computer_id)
general_settings:add_anchor(computer_id, 'left', 'left', -1, 1)
general_settings:add_anchor(computer_id, 'top', 'top', -1, 1)
general_settings:add_anchor(computer_id, 'right', 'right', -1, 1)

local computer_label = kidven.new('agui-label', 1, 1, 'Label: None.')

if os.getComputerLabel() then
  computer_label.text = 'Label: ' .. os.getComputerLabel()
end

general_settings:add(computer_label)
general_settings:add_anchor(computer_label, 'left', 'left', -1, 1)
general_settings:add_anchor(computer_label, 'top', 'bottom', computer_id, 0)
general_settings:add_anchor(computer_label, 'right', 'right', -1, 1)


local background_label = kidven.new('agui-label', 1, 1, 'BG: Loading...')

general_settings:add(background_label)
general_settings:add_anchor(background_label, 'left', 'left', -1, 1)
general_settings:add_anchor(background_label, 'top', 'bottom', -1, -1)
general_settings:add_anchor(background_label, 'right', 'right', -1, 4)

--[[
-- TODO: Implement a pop-up dialog for this.

local background = kidven.new('agui-button', 1, 1, '=', 3)

general_settings:add(background)
general_settings:add_anchor(background, 'left', 'right', background_label, 1)
general_settings:add_anchor(background, 'top', 'top', background_label, 0)
]]--

general_settings:reflow()

function update_general()
  local bg_file = kidven.new('kvio-bundle', settings:get_background())
  bg_file:load()

  local meta = bg_file:open("metadata", "r")
  background_label.text = 'BG: ' .. fs.getName(settings:get_background())

  for line in meta:lines() do
    local name, value = line:match("^([^:]+): (.+)$")

    if name == "Name" then
      background_label.text = 'BG: ' .. value
    end
  end

  meta:close()
end

-- Plugins!

local plugin_settings = new_tab('Plugins')

local enable_plugins = kidven.new('agui-checkbox', 2, 2, 'Enable Plugins')

plugin_settings:add(enable_plugins)
plugin_settings:add_anchor(enable_plugins, 'top', 'top', -1, 1)
plugin_settings:add_anchor(enable_plugins, 'left', 'left', -1, 1)

local plugs_disabled = kidven.new('agui-list', 2, 4, 1, 1)
local plugs_enabled = kidven.new('agui-list', 1, 1, 1, 1)

local plug_enable = kidven.new('agui-button', 1, 4, '<', 3)
local plug_disable = kidven.new('agui-button', 1, 1, '>', 3)

plugin_settings:add(plugs_enabled)

plugin_settings:add(plug_enable)
plugin_settings:add(plug_disable)

plugin_settings:add(plugs_disabled)

plugin_settings:add_anchor(plugs_enabled, 'top', 'bottom', enable_plugins, 1)
plugin_settings:add_anchor(plugs_enabled, 'left', 'left', -1, 1)
plugin_settings:add_anchor(plugs_enabled, 'bottom', 'bottom', -1, 0)
plugin_settings:add_anchor(plugs_enabled, 'right', 'middle', -1, 2)

plugin_settings:add_anchor(plug_enable, 'left', 'right', plugs_enabled, 1)
plugin_settings:add_anchor(plug_enable, 'top', 'top', -1, 4)

plugin_settings:add_anchor(plug_disable, 'left', 'right', plugs_enabled, 1)
plugin_settings:add_anchor(plug_disable, 'top', 'bottom', -1, -2)

plugin_settings:add_anchor(plugs_disabled, 'top', 'top', plugs_enabled, 0)
plugin_settings:add_anchor(plugs_disabled, 'left', 'right', plug_enable, 1)
plugin_settings:add_anchor(plugs_disabled, 'right', 'right', -1, 1)
plugin_settings:add_anchor(plugs_disabled, 'bottom', 'bottom', -1, 0)

plugin_settings:reflow()

app:subscribe('gui.button.pressed',
function(_, id)
  if id == plug_enable.agui_widget.id then
    settings:enable_plugin('menubar', plugs_disabled:get_current().label)
  elseif id == plug_disable.agui_widget.id then
    settings:disable_plugin('menubar', plugs_enabled:get_current().label)
  end
end)


function update_plugins()
  local plugins_enabled = settings:get_plugins_enabled()

  plugs_disabled:set_enabled(plugins_enabled)
  plugs_enabled:set_enabled(plugins_enabled)

  plug_disable:set_enabled(plugins_enabled)
  plug_enable:set_enabled(plugins_enabled)


  enable_plugins.agui_input.value = plugins_enabled

  if plugins_enabled then
    plugs_disabled:clear()
    plugs_enabled:clear()

    local plugins = {}

    for _, plug in ipairs(glox.get_plugins('menubar')) do
      plugins[plug] = false
    end

    for _, plug in ipairs(settings:get_plugins('menubar')) do
      plugins[plug] = true
    end

    for plug, enabl in pairs(plugins) do
      if enabl then
	      plugs_enabled:add(kidven.new('agui-list-item', plug))
      else
      	plugs_disabled:add(kidven.new('agui-list-item', plug))
      end
    end
  end
end

-- App Pane

local app_settings = new_tab('Apps')

local favourites_list = kidven.new('agui-list', 2, 2, 1, 1)

local add_button = kidven.new('agui-button', 2, 1, '+', 3)
local rem_button = kidven.new('agui-button', 3, 1, '-', 3)

app_settings:add(favourites_list)

app_settings:add(add_button)
app_settings:add(rem_button)

local fav_label = kidven.new('agui-label', favourites_list.agui_widget.width + 3, 4, 'Label', 10 - favourites_list.agui_widget.width - 5)
local fav_command = kidven.new('agui-label', favourites_list.agui_widget.width + 3, 6, 'Command', fav_label.agui_widget.width)

app_settings:add(fav_label)
app_settings:add(fav_command)

app_settings:add_anchor(favourites_list, 'left', 'left', -1, 2)
app_settings:add_anchor(favourites_list, 'top', 'top', -1, 2)
app_settings:add_anchor(favourites_list, 'bottom', 'bottom', -1, -1)
app_settings:add_anchor(favourites_list, 'right', 'middle', -1, 5)

app_settings:add_anchor(add_button, 'top', 'bottom', favourites_list, 0)
app_settings:add_anchor(add_button, 'left', 'left', favourites_list, 0)

app_settings:add_anchor(rem_button, 'top', 'bottom', favourites_list, 0)
app_settings:add_anchor(rem_button, 'left', 'left', favourites_list, 3)

app_settings:add_anchor(fav_label, 'left', 'right', favourites_list, 2)
app_settings:add_anchor(fav_label, 'right', 'right', -1, -1)
app_settings:add_anchor(fav_label, 'top', 'top', -1, 3)

app_settings:add_anchor(fav_command, 'left', 'right', favourites_list, 2)
app_settings:add_anchor(fav_command, 'right', 'right', -1, -1)
app_settings:add_anchor(fav_command, 'top', 'bottom', fav_label, 2)

app_settings:reflow()

function update_app()
  favourites_list:clear()

  local favs = settings:get_favourites()

  for _, fav in ipairs(favs) do
    favourites_list:add(kidven.new('glox-hb-result', fav[1], '', fav[2]))
  end

  rem_button:set_enabled(#favs > 0)
end

-- New Favourite pane.

local add_window = kidven.new('agui-window', 'Add Favourite', math.floor(main_window.agui_widget.width / 3 * 2), 8)

local prog_label = kidven.new('agui-input', 2, 2, add_window.agui_widget.width - 2)

app.shell = shell

local prog_search = kidven.new('glox-program-picker', app, prog_label.agui_widget.width, 3)

local prog_ok = kidven.new('agui-button', 2, 7, 'Ok')
local prog_cancel = kidven.new('agui-button', 4, 7, 'Cancel')

prog_search:move(2, 4)

add_window:add(prog_label)
add_window:add(prog_search)
add_window:add(prog_ok)
add_window:add(prog_cancel)

app:subscribe('gui.list.changed',
function(_, id, num, item)
  if id == favourites_list.agui_widget.id then
    fav_label.text = item.name
    fav_command.text = item.command
  end
end)


app:subscribe('gui.button.pressed',
function(_, id)
  local ok, err = pcall(
  function()
    if id == add_button.agui_widget.id then

      prog_search.agui_search.input_box.value = ''
      prog_label.value = ''

      add_window:select(prog_label)

      app:add(add_window)
      app:select(add_window)
    elseif id == rem_button.agui_widget.id then
      settings:remove_favourite(favourites_list:get_current().name)
    elseif id == prog_ok.agui_widget.id then
      settings:add_favourite(prog_label.value, prog_search.command)

      app:remove(add_window)
    elseif id == prog_cancel.agui_widget.id then
      app:remove(add_window)
    end
  end)

  if not ok then
    app.main_err = err
    app:quit()
  end
end)

-- Main Loop Stuff.

app:add(main_window)

app:subscribe('glox.settings.commit', function(_)
  update_general()
  update_plugins()
  update_app()
 end)

app:subscribe("gui.input.changed", function(_, id, value)
  if id == enable_plugins.agui_widget.id then
    settings:set_plugins_enabled(value)
  elseif id == show_tips.agui_widget.id then
    settings:set_show_tips(value)
  end
end)

app:subscribe('gui.resized', function()
  main_window:resize(term.getSize())

  general_settings.container:resize(main_window.agui_widget.width, main_window.agui_widget.height - 1)
  plugin_settings.container:resize(main_window.agui_widget.width, main_window.agui_widget.height - 1)
  app_settings.container:resize(main_window.agui_widget.width, main_window.agui_widget.height - 1)

  -- Re-flow the panes.

  general_settings:reflow()
  plugin_settings:reflow()
  app_settings:reflow()
end)


settings:load()

app:main()
