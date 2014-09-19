-- lint-mode: glox

_parent = 'veek-widget'

function Widget:init(app, width, height)
  self.veek_widget:init(1, 1, width, 1)

  self.veek_widget:add_flag('active')

  self.drawer_height = height

  self.app = app

  self.veek_widget.fg = 'glox-menubar-fg'
  self.veek_widget.bg = 'glox-menubar-bg'

  self.launcher_menu = new('veek-menu', app)

  self.plugins = {}
  self.plugin_offsets = {}
  self.minimised_offset = -1

  self.min_selected = 0

  self.app.event_loop:subscribe('glox.settings.commit',
  function()
    self.plugins = {}

    if self.app.settings:get_plugins_enabled() then
      for _, plug in ipairs(self.app.settings:get_plugins('menubar')) do
        table.insert(self.plugins, new('mb-plugin-' .. plug, app, self))
      end
    end
  end)
end

function Widget:is_expanded()
  return self.veek_widget.height > 1
end

-- TODO: These should animate
function Widget:collapse()
  self:resize(self.veek_widget.width, 1)
end

function Widget:expand()
  self.app:select(self)
  self:resize(self.veek_widget.width, self.drawer_height)
end

-- Render Functions
function Widget:draw_expanded(c)
  local offset = 1
  local msg = ""

  self.plugin_offsets = {}

  for _, plugin in ipairs(self.plugins) do
    if plugin:is_visible() and plugin:is_expandable() then
      self.plugin_offsets[offset] = plugin
      self.plugin_offsets[offset + 1] = plugin
      self.plugin_offsets[offset + 2] = plugin

      local p = plugin:cast('mb-plugin')

      c:move(1, offset)
      c:set_fg(p.colour_fg)
      c:set_bg(p.colour_bg)
      c:write("   ")
      c:move(1, offset + 1)
      c:write(" " .. p.text:sub(1, 1) .. " ")
      c:move(1, offset + 2)
      c:write("   ")

      local sub = c:sub(5, offset, c.width - 5, 3)

      sub:set_bg('glox-drawer-plugin-bg')
      sub:set_fg('glox-drawer-plugin-fg')

      sub:clear()
      sub:move(1, 1)

      if plugin:is_graphical() then
      	plugin:draw(sub)
      else
      	local old

      	if term.current then
      	  old = term.current()
      	end

      	term.redirect(sub:as_redirect())

      	print(plugin:details())

      	if term.current then
      	  term.redirect(old)
      	else
      	  term.restore()
      	end
      end

      offset = offset + 3
    end
  end

  if #self.app.minimised > 0 then
    c:move(1, offset)
    c:set_fg('glox-drawer-title-fg')
    c:set_bg('glox-drawer-title-bg')
    c:write(" ")
    c:write(("-"):rep(c.width - 2))
    c:write(" ")

    if pocket then
      msg = " Running Programs "
    else
      msg = " Minimised "
    end

    c:move(c.width / 2 - #msg / 2, offset)
    c:write(msg)

    self.minimised_offset = offset

    offset = offset + 1

    c:set_fg('glox-drawer-minimised-fg')
    c:set_bg('glox-drawer-minimised-bg')

    for i, win in ipairs(self.app.minimised) do
      c:move(1, offset)

      if i == self.min_selected then
        c:write('> ')
      else
        c:write('  ')
      end

      c:write(win:cast('veek-window').title)
      c:write(string.rep(' ', c.width - c.x))

      offset = offset + 1
    end
  else
    self.minimised_offset = -1
  end

  c:set_fg('glox-drawer-handle-fg')
  c:set_bg('glox-drawer-handle-bg')

  c:move(1, c.height)
  c:write(" ")
  c:write(("-"):rep(c.width - 2))
  c:write(" ")

  msg = "[ Glox Shell ]"
  c:move(c.width / 2 - #msg / 2, c.height)
  c:write(msg)
end

function Widget:draw_collapsed(c)
  local offset = c.width

  c:move(1, 1)

  c:set_fg('glox-menubar-launcher-fg')
  c:set_bg('glox-menubar-launcher-bg')
  c:write("%")

  if self.window and not self.window.veek_window.flags["glox.fullscreen"] then
    offset = offset - 4

    c:set_fg('glox-menubar-controls-fg')
    c:set_bg('glox-menubar-controls-bg')
    c:move(self.veek_widget.width - 2, 1)
    c:write("[ ]")

    if pocket then
      -- on Pocket, show the close button in the bar.
      c:move(self.veek_widget.width - 1, 1)
      c:set_fg('window-close-bg')
      c:set_bg('glox-menubar-controls-bg')
      c:write('x')
    else
      -- On !Pocket, show the un-embiggen button
      c:move(self.veek_widget.width - 1, 1)
      c:set_fg('window-maximise-bg')
      c:set_bg('glox-menubar-controls-bg')
      c:write("-")
    end
  end

  self.plugin_offsets = {}

  for _, plugin in ipairs(self.plugins) do
    if plugin:is_visible() then
      self.plugin_offsets[offset] = plugin

      local p = plugin:cast('mb-plugin')

      p.location = offset

      c:move(offset, 1)

      c:set_fg(p.colour_fg)
      c:set_bg(p.colour_bg)
      c:write(p.text:sub(1, 1))

      offset = offset - 1
    end
  end

  if self.window then
    c:set_fg('glox-menubar-window-title-fg')
    c:set_bg('glox-menubar-window-title-bg')

    local txt = self.window.veek_window.title

    if #txt > offset - 3 then
      txt = txt:sub(1, offset - 6) .. "..."
    end

    c:move(3, 1)
    c:write(txt)
  end
end

function Widget:set_embiggened(window)
  self.window = window
end

function Widget:show_menu()
  self.launcher_menu:clear()

  for _, fav in ipairs(self.app.settings:get_favourites()) do
    self.launcher_menu:add(fav[1],
    function()
      self.app:launch(fav[2])
    end)
  end

  self.launcher_menu:add_seperator()

  self.launcher_menu:add("Run...", function()
    local window = new('glox-rundialog', self.app)

    window.veek_widget.x = 1
    window.veek_widget.y = 2

    self.app:add(window)
    self.app:select(window)
  end)


  self.launcher_menu:add("Restart", function()
    os.reboot()
  end)

  self.launcher_menu:add("Shutdown", function()
    os.shutdown()
  end)


  self.launcher_menu:show(1, 2)
end


-- Widget hooks.

function Widget:draw(c, theme)
  c:move(1, 1)
  c:clear()

  if self:is_expanded() then
    self:draw_expanded(c)
  else
    self:draw_collapsed(c)
  end
end

function Widget:clicked(x, y, btn)
  if self:is_expanded() then
    self:collapse()
    if self.plugin_offsets[y] then
      self.plugin_offsets:clicked(btn)
    elseif self.minimised_offset > 0 and y > self.minimised_offset then
      if self.app.minimised[y - self.minimised_offset] then
	     self.app:restore(self.app.minimised[y - self.minimised_offset])
      end
    end
  else
    if x == 1 then
      self:show_menu()
    elseif self.window then
      if x == self.veek_widget.width - 1 then
	-- Acts as a close button when on Pocket
	if pocket then
	  self.app:close(self.window.screen.proc, self.window)
	else
	  self.app:unembiggen(self.window)
	end
      elseif x > self.veek_widget.width - 3 - #self.plugins and x < self.veek_widget.width - 3 then
	self.plugins[self.veek_widget.width - 2 - x]:clicked(btn)
      end
    elseif self.plugin_offsets[x] then
      self.plugin_offsets[x]:clicked(btn)
    end
  end
end

function Widget:dragged(x_del, y_del, btn)
  if btn == 1 then
    local new_h = self.veek_widget.height + y_del
    if new_h > self.drawer_height then
      new_h = self.drawer_height
    elseif new_h < 1 then
      new_h = 1
    end

    self:resize(self.veek_widget.width, new_h)
  end
end

function Widget:blur()
  self:collapse()
end

function Widget:key(k)
  if not self:is_expanded() then
    return false
  end

  if k == keys.up then
    if self.min_selected > 1 then
      self.min_selected = self.min_selected - 1
    else
      self.min_selected = #self.app.minimised
    end
  elseif k == keys.down then
    if self.min_selected < #self.app.minimised then
      self.min_selected = self.min_selected + 1
    else
      self.min_selected = 1
    end
  elseif k == keys.enter then
    if self.app.minimised[self.min_selected] then
      self.app:restore(self.app.minimised[self.min_selected])
    end
  else
    return false
  end

  return true
end

function Widget:ctrl_macro(k)
  if k == keys.d then
    if self:is_expanded() then
      self:collapse()
    else
      self:expand()
    end

    return true
  else
    for _, plugin in ipairs(self.plugins) do
      if plugin:macro(k) then
        return true
      end
    end

    return false
  end
end
