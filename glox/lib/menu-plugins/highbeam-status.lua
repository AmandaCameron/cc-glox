-- lint-mode: glox

-- HighBeam Status spinner.

_parent = 'mb-plugin'

function Plugin:init(app, mb)
  self.mb_plugin:init('/', app, mb)

  self.mb_plugin.colour_bg = 'glox-search-indexing-bg'
  self.mb_plugin.colour_fg = 'glox-search-indexing-fg'

  self.step = 0
  self.timer_id = -1

  app:subscribe('event.hb-ipc', function(_, cmd, arg)
    if cmd == 'status' then
      if arg == 'scanning' then
        self:spin()
      elseif arg == 'idle' then
        self:stop_spin()
      end
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
