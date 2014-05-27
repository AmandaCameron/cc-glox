-- AGUI Shell app.
-- Sub-classes agui-app and adds more stuff we need.

_parent = "agui-app"

function Object:init(disp, shell)
  self.agui_app:init(disp)

  self.shell = shell

  self.settings = new('glox-settings', self)

  -- Load in our spedeshal theme.
  if disp.isColour() then
    self.agui_app:load_theme("__LIB__/glox/theme")
  else
    self.agui_app:load_theme("__LIB__/glox/mono-theme")
  end

  self.agui_app.pool = new('glox-pool')

  self.pool = self.agui_app.pool

  local hooks = {}

  function hooks.error(_, err)
    self.agui_app.main_err = err
  end

  function hooks.die(_)
    self.agui_app.pool:stop()
  end

  self.agui_app.pool:new(function()
    self.event_loop:main()
  end, hooks)

  self.minimised = {}
  self.processes = {}
  self.window_procs = {}
  self.windows = {}

  self.event_loop:subscribe("glox.process.exit", function(_, id)
    for i, proc in ipairs(self.processes) do
      if proc.id == id then
        table.remove(self.processes, i)

        for _, win in ipairs(proc.windows) do
          if self.window == win then
            self.window = nil
            self.menu:set_embiggened(nil)
          end
        end

        return
      end
    end
  end)

  self.event_loop:subscribe('event.glox-ipc', function(_, call)
    if call == "settings_changed" then
      self.settings:load()
    end
  end)

  self.event_loop:subscribe("event.*", function(evt, ...)
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

  self.event_loop:subscribe("event.terminate", function(evt)
    local active = self.agui_app.main_window.gooey:get_focus()

    if active:is_a("app-window") then
      active.screen.proc:queue_event("terminate")
    end
  end)


  self.event_loop:subscribe("event.key", function(_, key)
    if key == keys.leftCtrl or key == keys.rightCtrl then
      self.ctrl_count = self.ctrl_count + 1

      if self.ctrl_count == 1 then
        self.pool:new(function()
          sleep(0.75)

          self.ctrl_count = 0
        end)
      end
    elseif key == keys.leftAlt or key == keys.rightAlt then
      self.menu:show_menu()
    elseif self.ctrl_count == 2 then
      self.ctrl_count = 0

      if self.menu:ctrl_macro(key) then
        -- Menu handled it.
      elseif key == keys.x then
        local focus = self.agui_app.main_window.gooey:get_focus()

        if focus and focus:is_a('app-window') then
          self:close(focus.screen.proc, focus)
        end
      elseif key == keys.m then
        local focus = self.agui_app.main_window.gooey:get_focus()

        if focus and focus:is_a('app-window') then
          self:minimise(focus)
        end
      elseif key == keys.tab then
        self.agui_app.main_window.gooey:focus_next()
      end
    end
  end)

  self.ctrl_count = 0


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

  if self.settings:is_first_run() then
    self:launch('glox-onboarding')
  end
end

function Object:init_picker()
  self.picker_window = new('agui-window', "Select App", 20, 16)

  local label = new("agui-textbox", 2, 2, 18, 2, "Select the program to open this with.")

  self.picker_window:add(label)

  self.picker_list = new('agui-list', 2, 6, 18, 10)

  self.picker_window:add(self.picker_list)

  self.picker_window.flags.closable = true

  local ok = new('agui-button', 5, 15, "Ok", 10)

  self.picker_window:add(ok)

  self:subscribe('gui.window.closed', function(_, id)
    if id == self.picker_window.agui_widget.id then
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
  elseif #programs > 0 then
    self.picker_list:clear()

    for _, program in ipairs(programs) do
      self.picker_list:add(new('glox-app-entry', program.name, program.command))
    end

    self:add(self.picker_window)
    self:select(self.picker_window)
  else
    local window = new('agui-window', "Error", 20, 5)

    window.agui_widget.x = math.floor(self.desktop.agui_widget.width / 2 - 10)
    window.agui_widget.y = math.floor(self.desktop.agui_widget.height / 2 - 2)

    local label = new('agui-label', 2, 2, "No application to handle " .. uri, 18)

    window:add(label)

    local ok_btn = new('agui-label', 7, 4, "Ok", 6)

    window:add(ok_btn)
    window:select(ok_btn)

    window.flags.closable = true

    self:add(window)
    self:select(window)

    local close_evt_id
    local btn_evt_id

    close_evt_id = self:subscribe('gui.window.closed', function(_, id)
      if id == window.agui_widget.id then
        self:remove(window)

        self:unsubscribe('gui.window.closed', close_evt_id)
        self:unsubscribe('gui.button.pressed', ok_evt_id)
      end
    end)

    btn_evt_id = self:subscribe('gui.button.pressed', function(_, id)
      if id == ok_btn.agui_widget.id then
        self:remove(window)

        self:unsubscribe('gui.window.closed', close_evt_id)
        self:unsubscribe('gui.button.pressed', btn_evt_id)
      end
    end)
  end
end

function Object:launch(cmdLine)
  local window = new('app-window', self, cmdLine, 30, 10)
  window.agui_widget.x = 4
  window.agui_widget.y = 3

  window.screen.proc.windows = { window }

  self:add(window)
  self:select(window)

  if pocket then
    self:embiggen(window)
  else
    -- Standard flags.
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

  function term.setFlags(flags)
    local old = proc.windows[1]:cast('agui-window').flags
    proc.windows[1]:cast('agui-window').flags = {}

    for _, flag in ipairs(flags) do
      proc.windows[1]:cast('agui-window').flags[flag] = true

      if flag == "glox.fullscreen" and not pocket then
        self:embiggen(proc.windows[1])
      end
    end
  end

  function term.getFlags()
    local flags = {}

    for flag, _ in pairs(proc.windows[1]:cast('agui-window').flags) do
      table.insert(flags, flag)
    end

    table.insert(flags, 'glox.identifier')

    return flags
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
  if self.window == window then
    self.window = nil
    self.menu:set_embiggened(nil)
  end

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
