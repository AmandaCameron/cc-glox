-- @Name: Glox Settings
-- @Description: Settings program for Glox.
-- @Author: Amanda Cameron
-- @Icon[4x3]: __LIB__/glox/res/icons/glox-settings

-- Settings program for glox

os.loadAPI("__LIB__/glox/glox")

local app = kidven.new('veek-app')

local settings = kidven.new('glox-settings', app)

local main_window = kidven.new('veek-tab-bar', 1, 1, term.getSize())

-- Functions!

local function new_tab(name)
  local cont = kidven.new('veek-container', 1, 1, main_window.veek_widget.width, main_window.veek_widget.height - 1)

  main_window:add_tab(name, cont)

  return kidven.new('veek-layout', cont)
end

-- General Settings.

local general_settings = new_tab('General')

local computer_id = kidven.new('veek-label', 1, 1, 'ID: ' .. os.getComputerID())

general_settings:add(computer_id)
general_settings:add_anchor(computer_id, 'left', 'left', -1, 1)
general_settings:add_anchor(computer_id, 'top', 'top', -1, 1)
general_settings:add_anchor(computer_id, 'right', 'right', -1, 1)

local computer_label = kidven.new('veek-label', 1, 1, 'Label: None.')

if os.getComputerLabel() then
  computer_label:set_text('Label: ' .. os.getComputerLabel())
end

general_settings:add(computer_label)
general_settings:add_anchor(computer_label, 'left', 'left', -1, 1)
general_settings:add_anchor(computer_label, 'top', 'bottom', computer_id, 0)
general_settings:add_anchor(computer_label, 'right', 'right', -1, 1)


local background_label = kidven.new('veek-label', 1, 1, 'BG: Loading...')

general_settings:add(background_label)
general_settings:add_anchor(background_label, 'left', 'left', -1, 1)
general_settings:add_anchor(background_label, 'top', 'bottom', -1, -1)
general_settings:add_anchor(background_label, 'right', 'right', -1, 4)

-- TODO: Implement a pop-up dialog for this.

local background = kidven.new('veek-button', 1, 1, '=', 3)

general_settings:add(background)
general_settings:add_anchor(background, 'left', 'right', background_label, 1)
general_settings:add_anchor(background, 'top', 'top', background_label, 0)

general_settings:reflow()

local function bg_get_label(file)
  local bg_file = kidven.new('kvio-bundle', file)
  bg_file:load()

  local meta = bg_file:open("metadata", "r")

  for line in meta:lines() do
    local name, value = line:match("^([^:]+): (.+)$")

    if name == "Name" then
      meta:close()

      return value
    end
  end

  meta:close()

  return fs.getName(file)
end

local function update_general()
  background_label:set_text('BG: ' .. bg_get_label(settings:get_background()))
end

app:subscribe('gui.button.pressed', function(_, id)
  if id == background.veek_widget.id then
    local menu = kidven.new('veek-menu', app)

    for _, file in ipairs(fs.list("__LIB__/glox/res/backgrounds")) do
      menu:add(bg_get_label(file), function()
        settings:set_background(file)

        menu:hide()
      end)
    end

    menu:show(background.veek_widget.x, background.veek_widget.y + 1)
  end
end)

-- Plugins!

local plugin_settings = new_tab('Plugins')

local enable_plugins = kidven.new('veek-checkbox', 2, 2, 'Enable Plugins')

plugin_settings:add(enable_plugins)
plugin_settings:add_anchor(enable_plugins, 'top', 'top', -1, 1)
plugin_settings:add_anchor(enable_plugins, 'left', 'left', -1, 1)

local plugs_disabled = kidven.new('veek-list', 2, 4, 1, 1)
local plugs_enabled = kidven.new('veek-list', 1, 1, 1, 1)

local plug_enable = kidven.new('veek-button', 1, 4, '<', 3)
local plug_disable = kidven.new('veek-button', 1, 1, '>', 3)

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

app:subscribe('gui.button.pressed', function(_, id)
  if id == plug_enable.veek_widget.id then
    settings:enable_plugin('menubar', plugs_disabled:get_current().label)
  elseif id == plug_disable.veek_widget.id then
    settings:disable_plugin('menubar', plugs_enabled:get_current().label)
  end
end)


local function update_plugins()
  local plugins_enabled = settings:get_plugins_enabled()

  plugs_disabled:set_enabled(plugins_enabled)
  plugs_enabled:set_enabled(plugins_enabled)

  plug_disable:set_enabled(plugins_enabled)
  plug_enable:set_enabled(plugins_enabled)


  enable_plugins.veek_input.value = plugins_enabled

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
        plugs_enabled:add(kidven.new('veek-list-item', plug))
      else
        plugs_disabled:add(kidven.new('veek-list-item', plug))
      end
    end
  end
end

-- App Pane

local app_settings = new_tab('Apps')

local favourites_list = kidven.new('veek-list', 2, 2, 1, 1)

local add_button = kidven.new('veek-button', 2, 1, '+', 3)
local rem_button = kidven.new('veek-button', 3, 1, '-', 3)

app_settings:add(favourites_list)

app_settings:add(add_button)
app_settings:add(rem_button)

local fav_label = kidven.new('veek-label', favourites_list.veek_widget.width + 3, 4, 'Label', 10 - favourites_list.veek_widget.width - 5)
local fav_command = kidven.new('veek-label', favourites_list.veek_widget.width + 3, 6, 'Command', fav_label.veek_widget.width)

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

local function update_app()
  favourites_list:clear()

  local favs = settings:get_favourites()

  for _, fav in ipairs(favs) do
    local item = kidven.new('veek-list-item', fav[1])
    item.command = fav[2]

    favourites_list:add(item)
  end

  rem_button:set_enabled(#favs > 0)
end

-- New Favourite pane.

local add_window = app:new_window('Add Favourite', math.floor(main_window.veek_widget.width / 3 * 2), 8)
add_window:hide()

local prog_label = kidven.new('veek-input', 2, 2, math.floor(main_window.veek_widget.width / 3 * 2))

app.shell = shell

local prog_search = kidven.new('glox-program-picker', app, prog_label.veek_widget.width, 3)

local prog_ok = kidven.new('veek-button', 2, 7, 'Ok')
local prog_cancel = kidven.new('veek-button', 4, 7, 'Cancel')

prog_search:move(2, 4)

add_window:add(prog_label)
add_window:add(prog_search)
add_window:add(prog_ok)
add_window:add(prog_cancel)

app:subscribe('gui.list.changed', function(_, id, num, item)
  if id == favourites_list.veek_widget.id then
    fav_label:set_text(item.label)
    fav_command:set_text(item.command)
  end
end)


app:subscribe('gui.button.pressed', function(_, id)
  local ok, err = pcall(
  function()
    if id == add_button.veek_widget.id then

      prog_search.veek_search.input_box.value = ''
      prog_label.value = ''

      add_window:select(prog_label)

      app:add(add_window)
      app:select(add_window)
    elseif id == rem_button.veek_widget.id then
      settings:remove_favourite(favourites_list:get_current().name)
    elseif id == prog_ok.veek_widget.id then
      settings:add_favourite(prog_label.value, prog_search.command)

      app:remove(add_window)
    elseif id == prog_cancel.veek_widget.id then
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
  local ok, err = pcall(function()
    update_general()
    update_plugins()
    update_app()
  end)

  if not ok then
    app.main_err = err
    app:quit()
  end
end)

app:subscribe("gui.input.changed", function(_, id, value)
  if id == enable_plugins.veek_widget.id then
    settings:set_plugins_enabled(value)
  end
end)

app:subscribe('gui.resized', function()
  main_window:resize(term.getSize())

  general_settings.container:resize(main_window.veek_widget.width, main_window.veek_widget.height - 1)
  plugin_settings.container:resize(main_window.veek_widget.width, main_window.veek_widget.height - 1)
  app_settings.container:resize(main_window.veek_widget.width, main_window.veek_widget.height - 1)

  -- Re-flow the panes.

  general_settings:reflow()
  plugin_settings:reflow()
  app_settings:reflow()
end)


settings:load()

app:main()
