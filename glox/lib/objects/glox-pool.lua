-- lint-mode: glox-object

-- A Re-iomplementation of lib-thread's thread pool with
-- additional stuff bolted on.

_parent = 'object'

function Object:init()
  self.threads = {}
  self.id = 0
end

function Object:queue_event(id, evt, ...)
  if not self.threads[id] then
    return
  end

  if not self.threads[id].has_queue then
    return
  end

  table.insert(self.threads[id].queue, { evt, ... })
end

function Object:new(func, hdlr, opts)
  local opts = opts or {}

  self.id = self.id + 1

  local id = self.id

  local t = term.native

  if term.current then
    t = term.current()
  end

  self.threads[id] = {
    -- Basic state.
    co = coroutine.create(func),
    filter = nil,
    handler = hdlr or {},

    -- Terminal output state
    redir = opts.terminal or t,
    term_hist = {},

    -- Seperate event queue keeping.
    has_queue = opts.has_queue,
    queue = { {} }, -- Give us a single event to start us
    -- off with.

    -- Event state keeping.
    timers = {},
    modem = {},
  }

  return id
end

function Object:stop()
  self.running = false

  os.queueEvent("boom")
end

function Object:main()
  local evt = nil
  local args = {}

  local t_redirect = term.redirect
  local t_restore = term.restore
  local t_current = term.current
  local os_queueEvent = os.queueEvent
  local os_startTimer = os.startTimer
  local peripheral_call = peripheral.call
  local rednet_open = rednet.open
  local rednet_close = rednet.close

  local modem_open = {}

  local orig_term

  if t_current then
    orig_term = term.current()

    function term.current()
      if not self.threads[self.active] then
        return nil
      end

      return self.threads[self.active].redir
    end
  else
    function term.restore()
      t_restore()
      self.threads[self.active].redir = table.remove(self.threads[self.active].term_hist, 1)
      t_redirect(self.threads[self.active].redir)
    end
  end

  function term.redirect(target)
    if orig_term then
      if not self.threads[self.active] then
        return nil
      end

      local old = self.threads[self.active].redir
      self.threads[self.active].redir = target

      t_redirect(target)

      return old
    end

    table.insert(self.threads[self.active].term_hist, 1,
    self.threads[self.active].redir)

    t_restore()
    self.threads[self.active].redir = target
    t_redirect(target)
  end

  function term.newWindow(...)
    return self.threads[self.active].redir.newWindow(...)
  end

  function term.activeWindow()
    return self.threads[self.active].redir.activeWindow()
  end

  function os.queueEvent(...)
    local evt = {...}

    if evt[1] == "rednet_message" or evt[1]:sub(-3) == "ipc" then
      -- Short-circuit in the case of an IPC event and rednet.

      os_queueEvent(...)
    end

    if not self.threads[self.active] then
      -- Broken state.
      return
    end

    if self.threads[self.active].has_queue then
      self:queue_event(self.active, ...)
    else
      os_queueEvent(...)
    end
  end

  function os.startTimer(timeout)
    if not self.threads[self.active] then
      return -1
    end

    local tid = os_startTimer(timeout)

    self.threads[self.active].timers[tid] = true

    return tid
  end

  --[[
  function peripheral.call(side, method, ...)
    if peripheral.getType(side) == "modem" then
      if not modem_open[side] then
        modem_open[side] = {}
      end

      -- Handle the calls.
      if method == "open" then
        local port = {...}
        if not modem_open[side][port] then
          modem_open[side][port] = 0
        end

        if not self.threads[self.active].modem[side] then
          self.threads[self.active].modem[side] = kidven.new('kvu-set')
        end

        modem_open[side][port] = modem_open[side][port] + 1

        self.threads[self.active].modem[side]:add(port)
      elseif method == "close" then
        local port = {...}

        if modem_open[side][port] then
          modem_open[side][port] = modem_open[side][port] - 1

          self.threads[self.active].modem[side]:remove(port)
        end
      elseif method == "closeAll" then
        for port in self.threads[self.active].modem[side]:iter() do
          if modem_open[side][port] > 0 then
            modem_open[side][port] = modem_open[side][port] - 1
          else
            peripheral_call(side, "close", port)
          end
        end

        return
      end
    end

    return peripheral_call(side, method, ...)
  end

  function rednet.open(side)
    if self.threads[self.active].rednet_open then
      rednet.close()
    end

    if side then
      peripheral.call(side, "open", 65535)
      peripheral.call(side, "open", os.getComputerID())

      self.threads[self.active].rednet_open = side
    else
      for _, side in ipairs(peripheral.getNames()) do
      	if peripheral.getType(side) == "modem" then
      	  rednet.open(side)
      	  return
      	end
      end
    end
  end

  function rednet.close(side)
    local side = side or self.threads[self.active].rednet_open

    if side then
      peripheral.call(side, "close", 65535)
      peripheral.call(side, "close", os.getComputerID())
      self.threads[self.active].rednet_open = nil
    end
  end ]]
  
  self.running = true

  -- Error logging.

  local ok, err = pcall(function()
    while self.running do
      for id, t in pairs(self.threads) do
        self.active = id

        t_redirect(t.redir)

        if evt == "timer" then
          if t.timers[args[1]] then
            self:run_thread(t, evt, unpack(args))

            t.timers[args[1]] = nil
          end
	      elseif evt == "modem_message" then
        	  self:run_thread(t, "modem_message", unpack(args))
      	elseif evt == "rednet_message" then
      	  self:run_thread(t, "rednet_message", unpack(args))
              elseif t.has_queue then
      	  while #t.queue > 0 do
      	    self:run_thread(t, unpack(table.remove(t.queue, 1)))
      	  end
      	else
      	  self:run_thread(t, evt, unpack(args))
      	end

      	if not orig_term then
      	  t_restore()
      	else
      	  -- Emulate the t_restore

      	  t_redirect(orig_term)
      	end
      end

      local graves = {}

      local n = 0

      for id, t in pairs(self.threads) do
      	n = n + 1

      	if coroutine.status(t.co) == "dead" then
      	  table.insert(graves, id)
      	end
      end

      for _, grave in ipairs(graves) do
      	if self.threads[grave] then
      	  if self.threads[grave].handler.die then
      	    self.threads[grave].handler:die()
      	  end

      	  self.threads[grave] = nil
      	end

      	n = n - 1
      end

      if n > 0 then
      	args = { os.pullEventRaw() }
      	evt = table.remove(args, 1)
      else
      	break
      end
    end
	end)

  term.redirect = t_redirect
  term.newWindow = nil
  term.activeWindow = nil

  if orig_term then
    term.current = t_current
  else
    term.restore = t_restore
  end


  os.queueEvent = os_queueEvent
  os.startTimer = os_startTimer
  peripheral.call = peripheral_call
  rednet.open = rednet_open
  rednet.close = rednet_close

  if not ok then
    -- Pass the error up the stack, now that we've cleaned up the environment.
    error(err)
  end
end

function Object:run_thread(t, evt, ...)
  if not t.filter or t.filter == evt or evt == "terminate" then
    local ok, res = coroutine.resume(t.co, evt, ...)

    if not ok then
      if t.handler.error then
        t.handler:error(res)
      end
    else
      if t.handler.yield then
        t.handler:yield(res)
      end

      t.filter = res
    end
  end
end
