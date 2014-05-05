-- AGUI Shell app.
-- Sub-classes agui-app and adds more stuff we need.

_parent = "agui-app"

function Object:init(disp, shell)
  self.agui_app:init(disp)

  self.shell = shell

  self.settings = new('glox-settings', self)

  -- Load in our spedeshal theme.
  self.agui_app:load_theme("__LIB__/glox/theme")

  self.agui_app.pool = new('glox-pool')

  self.pool = self.agui_app.pool

  local hooks = {}

  function hooks.error(_, err)
    self.agui_app.main_err = err
  end

  function hooks.die(_)
    self.agui_app.pool:stop()
  end

  self.agui_app.pool:new(
  function()
    self.event_loop:main()
  end, hooks)
  
  self.minimised = {}
  self.processes = {}
  self.window_procs = {}
  self.windows = {}

  self.event_loop:subscribe("glox.process.exit",
  function(_, id)
    for i, proc in ipairs(self.processes) do
      if proc.id == id then
        table.remove(self.processes, i)
        return
      end
    end
  end)

  self.event_loop:subscribe('event.glox_ipc',
  function(_, call)
    if call == "settings_changed" then
      self.settings:load()
    end
  end)

  self.event_loop:subscribe("event.*",
  function(evt, ...)
    -- Pass through all (Well, most.) non-gooey events.
    local evt = evt:sub(7)
    if evt ~= "key" and evt ~= "char" and evt:sub(1, 5) ~= "mouse" and evt ~= "modem_message" 
    and evt ~= "rednet_message" and evt ~= "terminate" then
      for _, proc in ipairs(self.processes) do
      	proc:queue_event(evt, ...)
      end
    end
  end)
  
  -- Clear out the agui event loop killer, replace it with something sane for a multitasking "OS"
  self.event_loop["event.terminate"] = {}
  
  self.event_loop:subscribe("event.terminate",
  function(evt)
    local active = self.agui_app.main_window.gooey:get_focus()

    if active:is_a("app-window") then
      active.screen.proc:queue_event("terminate")
    end
  end)


  self.app_db = new('ciiah-database')
  self.highbeam = new('hb-connection')

  self.menu = new('glox-menubar',
  self,
  self.agui_app.main_window.gooey.agui_widget.width, 
  self.agui_app.main_window.gooey.agui_widget.height)

  self.desktop = new('glox-desktop',
  self,
  self.agui_app.main_window.gooey.agui_widget.width,
  self.agui_app.main_window.gooey.agui_widget.height - 1)

  self.settings:load()

  self:add(self.menu)
  self:add(self.desktop)

  self:init_picker()
end

function Object:init_picker()
  self.picker_window = new('agui-window', "Select App", 10, 16)

  local label = new("agui-textbox", 2, 2, 8, 2, "Select the program to open this with")

  self.picker_window:add(label)

  self.picker_list = new('agui-list', 2, 6, 8, 10)

  self.picker_window:add(self.picker_list)

  self.picker_window.flags.closable = true

  local ok = new('agui-button', 5, 15, "Ok")

  self.picker_window:add(ok)

  self:subscribe('gui.window.closed', function(_, id)
    if id == window.agui_widget.id then
      self:remove(self.picker_window)
    end
  end)

  self:subscribe('gui.button.clicked', function(_, id)
    if id == ok.agui_widget.id then
      if self.picker_list:get_selected() then 
        self:launch(self.picker_list:get_selected().command)
        self:remove(self.picker_window)
      end
    end
  end)
end


function Object:open(uri, mime)
  local programs = self.app_db:resolve(uri, mime)

  if #programs == 0 then
    -- TODO
  end

  if #programs == 1 then
    self:launch(programs[1].command)
  else
    self.picker_list:clear()

    for _, program in ipairs(programs) do
      self.picker_list:add(new('glox-app-entry', program.name, program.command))
    end

    self:add(self.picker_window)
    self:select(self.picker_window)
  end
end

function Object:launch(cmdLine)
  local window = new('app-window', self, true, cmdLine, 30, 10)
  window.agui_widget.x = 4
  window.agui_widget.y = 3

  window.screen.proc.windows = { window }
  
  self:add(window)
  self:select(window)

  if pocket then
    self:embiggen(window)
  else
    -- Standard fl.
    window:add_flag("closable")
    window:add_flag("minimisable")
    window:add_flag("maximisable")
    window:add_flag("resizable")
  end

  return window
end

function Object:new_process(cmdLine, term)

  local proc = new('glox-process', self, cmdLine, term)

  -- Insert the newWindow additions to the term API

  function term.setTitle(new_title)
    proc.windows[1]:cast('agui-window').title = new_title
  end

  function term.activeWindow()
    return self:active_window()
  end

  function term.newWindow(title, width, height)
    local window = new('app-window', self, true, nil, width, height)
    window.agui_window.title = title

    local screen = window.screen.app_screen

    local id ='glox-' .. window.agui_widget.id

    window.screen.proc = proc

    window:move(4, 3)

    self:add(window)
    self:select(window)

    function screen.term.setTitle(title)
      window.agui_window.title = title
    end

    function screen.term.setSize(width, height)
      window:resize(width, height)
    end

    function screen.term.show()
      self:add(window)
      self:select(window)

      window:add_flag('visible')
    end

    function screen.term.hide()
      self:remove(window)

      window:rem_flag('visible')
    end

    function screen.term.setFlags(flags)
      local old = window.agui_window.flags
      window.agui_window.flags = {}
      
      for _, flag in ipairs(flags) do
        window.agui_window.flags[flag] = true
      end
    end

    function screen.term.getFlags()
      local flags = {}

      for flag, _ in pairs(window.agui_window.flags) do
        table.insert(flags, flag)
      end

      table.insert(flags, 'agui-shell.identifier')

      return flags
    end

    table.insert(proc.windows, window)
    self.window_procs[window.agui_widget.id] = proc
    self.windows[id] = window

    return id, screen.term
  end

  table.insert(self.processes, proc)

  return proc
end

function Object:unembiggen(window)
  if pocket then
    self:minimise(window)
  end

  self.menu:set_embiggened(nil)

  window:rem_flag('maximised')

  self.window = nil
  window.fullscreen = false
  window:resize(window.prev_w, window.prev_h)
  window:move(window.prev_x, window.prev_y)
end

function Object:embiggen(window)
  if self.window then
    self:unembiggen(self.window)
  end

  self.menu:set_embiggened(window)

  window:add_flag('maximised')

  -- Store the previous domensions & location.
  window.prev_x, window.prev_y = window.agui_widget.x, window.agui_widget.y
  window.prev_w = window.agui_widget.width
  window.prev_h = window.agui_widget.height

  self.window = window
  self.window.fullscreen = true
  self.window:resize(self.desktop.agui_widget.width, self.desktop.agui_widget.height)
  self.window:move(1, 2)
end

function Object:minimise(window)
  table.insert(self.minimised, window)

  window:add_flag('minimised')

  self:remove(window)
end

function Object:restore(window)
  local old = self.minimised

  window:rem_flag('minimised')

  self.minimised = {}

  for _, win in ipairs(old) do
    if win.agui_widget.id ~= window.agui_widget.id then
      table.insert(self.minimised, win)
    end
  end

  self:add(window)
  self:select(window)

  if pocket then
    self:embiggen(window)
  end
end

function Object:close(process, window)
  if self.window == window then
    self.window = nil
    self.menu:set_embiggened(nil)
  end

  -- Handle sub-window case.
  if self.window_procs[window.agui_widget.id] then
    self.window_procs[window.agui_widget.id]:queue_event('window_close', 'glox-' .. window.agui_widget.id)

    return
  end

  process:queue_event("terminate")

  self:remove(window)
end

function Object:active_window()
  local focused = self.agui_app.main_window.gooey:get_focus()

  if focused and focused:is_a('app-window') then
    if self.window_procs[focused.agui_widget.id] then
      return 'glox-' .. focused.agui_widget.id
    else
      return 'main-window'
    end
  end
end
