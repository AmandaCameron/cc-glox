-- This has been made to maintain compatability with old code.
-- It should be nuked from orbit ASAP

-- lint-mode: glox

_parent = 'agui-window'

function Widget:init(app, cmdLine, width, height)
  self.agui_window:init(cmdLine, width, height)

  self.screen = new('app-container', app, cmdLine, width, height)

  self:add(self.screen)

  self.app = app

  app:subscribe('gui.window.closed', function(_, id)
    if id == self.agui_widget.id then
      app:close(self.screen.proc, self)
    end
  end)

  app:subscribe('gui.window.resize', function(_, id)
    if id == self.agui_widget.id then
      if self.fullscreen then
      	self.screen:resize(self.agui_widget.width, self.agui_widget.height)
      else
      	self.screen:resize(self.agui_widget.width - 2, self.agui_widget.height - 2)
      end
    end
  end)

  app:subscribe('gui.window.minimised', function(_, id)
    if id == self.agui_widget.id then
      app:minimise(self)
    end
  end)

  app:subscribe('gui.window.maximised', function(_, id)
    if id == self.agui_widget.id then
      app:embiggen(self)

      self.screen:resize(self.agui_widget.width, self.agui_widget.height)
    end
  end)

  self.fullscreen = false
end

function Widget:draw(canvas)
  if self.fullscreen then
    self.screen:draw(canvas)
  else
    self.agui_window:draw(canvas)
  end
end

-- Eat the f10 thing.

function Widget:key(key)
  if self.fullscreen then
    return self.agui_container:key(key)
  end

  return self.agui_window:key(key)
end

-- Focused flag

function Widget:focus()
  self.agui_container:focus()
  self.agui_widget:focus()

  self:add_flag('focused')
end

function Widget:blur()
  self.agui_container:blur()
  self.agui_widget:blur()

  if self.agui_window.flags.modal then
    local n_w = self.app.agui_app.main_window.gooey:get_focus()

    if n_w.screen and n_w.screen.proc.id == self.screen.proc.id then
      self.app:select(self)
    end
  end

  self:rem_flag('focused')
end

-- Fullscreen fixes.

function Widget:clicked(x, y, btn)
  if self.fullscreen then
    self.screen:clicked(x, y, btn)
  else
    self.agui_window:clicked(x, y, btn)
  end
end

function Widget:dragged(x, y, btn)
  if self.fullscreen then
    self.screen:dragged(x, y, btn)
  else
    self.agui_window:dragged(x, y, btn)
  end
end

-- Flags!

function Widget:add_flag(flag)
  local id = 'main-window'

  if self.app.window_procs[self.agui_widget.id] then
    id = 'glox-' .. self.agui_widget.id
  end

  self.screen.proc:queue_event('window_flag_added', id, flag)

  self.agui_window.flags[flag] = true
end


function Widget:rem_flag(flag)
  local id = 'main-window'

  if self.app.window_procs[self.agui_widget.id] then
    id = 'glox-' .. self.agui_widget.id
  end

  self.screen.proc:queue_event('window_flag_removed', id, flag)

  self.agui_window.flags[flag] = nil
end

function Widget:resize(w, h)
  self.agui_widget:resize(w, h)
  self:trigger('gui.window.resize')
end
