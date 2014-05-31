-- lint-mode: kidven

-- Service Object.
-- Listens to stuff and does fun things.

_parent = "event-loop"

function Object:init(name, desc)
  self.event_loop:init()

  self.name = name
  self.desc = desc
  self.errored = false

  self.state = 'unkown'
  self.details = 'Unknown State'
end

function Object:describe()
  return "[ Service " .. self.name .. ": " .. self.desc .. " ]"
end

-- Thread Hooks.

function Object:created()
  self.state = 'running'
  self.details = 'Service is Running'
end

function Object:error(err)
  self.state = 'failed'
  self.details = err
  self.errored = true
end

function Object:die()
  if not self.errored then
    self.state = 'stopped'
  end
end
