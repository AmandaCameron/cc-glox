-- lint-mode: kidven

_parent = 'object'

function Object:init()
  --self.kv_interface:init()
end

function Object:send(msg)
  error("Method must be implemented.", 2)
end

function Object:subscribe(func)
  error("Method must be implemented.", 2)
end
