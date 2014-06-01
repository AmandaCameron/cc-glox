-- lint-mode: kidven

-- Channel object for communicating over the modem API.

_parent = 'kvio-channel'

function Object:init(modem, dest, port)
  self.kvio_channel:init()

  kidven.verify({ modem, dest, port }, 'kvio-modem', 'number', '?number')

  self.modem = modem

  self.destination = dest
  self.port = port or math.floor(math.random(1, 65000)) + 255

  self.id = self.modem.id .. "-" .. dest .. "-" .. self.port
end

function Object:subscribe(func)
  self.modem.pump:subscribe('network.modem.recv',
  function(_, id, sender, dest, msg, dist)
    if id == self.modem.id then
      if dest == self.port then
	func(sender, msg, dist)
      end
    end
  end)
end

function Object:send(msg)
  self.modem:transmit(self.dest, self.port, msg)
end
