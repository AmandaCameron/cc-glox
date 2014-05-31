-- lint-mode: kidven

-- Modem wrapper object for lib-kvio

_parent = 'object'

function Object:init(pump, side)
  self.pump = pump
  self.side = side

  if side then
    if peripheral.getType(side) ~= "modem" then
      error('Not a modem on ' .. side, 3)
    end
  else
    for _, s in ipairs({ 'top', 'bottom', 'left', 'right', 'front', 'back' }) do
      if peripheral.getType(s) == "modem" then
	self.side = s
	break
      end
    end
  end

  if not self.side then
    error("No modem found.")
  end

  self.peripheral = peripheral.wrap(self.side)

  self.id = os.getComputerID() .. '-' .. self.side

  self.open_ports = new('kvu-set')

  self.pump:subscribe('event.modem_message',
  function(_, side, dest, sender, msg, dist)
    if side == self.side then
      pump:trigger('network.modem.recv', self.id, sender, dest, msg, dist)
    end
  end)
end

function Object:is_open(port)
  return self.peripheral.isOpen(port)
end

function Object:transmit(dest, reply, msg)
  return self.peripheral.transmit(dest, reply, msg)
end

function Object:open(port)
  if not self:is_open(port) then
    self.peripheral.open(port)

    self.open_ports:add(port)
  end
end

function Object:close(port)
  if self:is_open(port) then
    self.peripheral.close(port)

    self.open_ports:remove(port)
  end
end

function Object:close_all()
  for port in self.open_ports:iter() do
    self.peripheral.close(port)
  end

  self.open_ports:clear()
end
