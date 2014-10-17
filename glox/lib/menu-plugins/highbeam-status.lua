-- lint-mode: glox-plugin

-- HighBeam Status spinner.

_parent = 'mb-plugin'

function Plugin:init(app, mb)
  self.mb_plugin:init('/', app, mb)

  self.mb_plugin.colour_bg = 'glox-search-indexing-bg'
  self.mb_plugin.colour_fg = 'glox-search-indexing-fg'

  self.step = 0
  self.timer_id = -1

  self.tasks = {}
  self.num_tasks = 0

  app:subscribe('event.hb-ipc', function(_, cmd, arg, ...)
    local args = { ... }
    if cmd == 'status' then
      if arg == 'scanning' then
        self:spin()
      elseif arg == 'idle' then
        self:stop_spin()
      end

    elseif cmd == "task.begin" then
      self.tasks[arg] = { 0, 1 }
      self.num_tasks = self.num_tasks + 1

      self:update_window()
    elseif cmd == "task.progress" then
      self.tasks[arg] = { args[1], args[2] }

      self:update_window()
    elseif cmd == "task.done" then
      self.tasks[arg] = nil
      self.num_tasks = self.num_tasks - 1

      self:update_window()
    end
  end)

  app:subscribe('event.timer', function(_, id)
    if id == self.timer_id then
      self.step = self.step + 1

      if self.step > 4 then
        self.step = 1
      end

      self.mb_plugin.text = string.sub("/-\\|", self.step, self.step)

      self.timer_id = os.startTimer(0.25)
    end
  end)
end

function Plugin:clicked()
  self:update_window()

  self.popup:show()
end

function Plugin:update_window()
  if self.popup == nil then
    self.popup = self:create_popup(20, 0)
  end

  self.popup.veek_container.children = {}

  if self.num_tasks > 0 then
    self.popup:resize(20, self.num_tasks * 2)

    local y = 0

    for name, data in pairs(self.tasks) do
      y = y + 1

      local label = new('veek-label', 1, y, name, 20)

      self.popup:add(label)

      y = y + 1

      local prog = new('veek-progress-bar', 1, y, 20)

      if name ~= "Scan" then
        prog.format = data[1] .. '/' .. data[2]
      end

      prog.progress = data[1] / data[2]

      self.popup:add(prog)
    end
  else
    self.popup:resize(20, 5)

    self.popup:add(new('veek-label', 2, 3, 'Highbeam Inactive'))
  end
end

function Plugin:spin()
  self.timer_id = os.startTimer(0.25)
end

function Plugin:stop_spin()
  if os.cancelTimer then
    os.cancelTimer(self.timer_id)
  end

  self.timer_id = -1
end

function Plugin:is_expandable()
  return true
end

function Plugin:details()
  return "HighBeam is indexing..."
end

function Plugin:is_visible()
  return self.timer_id >= 0
end
