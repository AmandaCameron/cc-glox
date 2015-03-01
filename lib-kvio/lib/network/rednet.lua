-- lint-mode: kidven

-- Kidven-based rednet networking!
-- Back-ports 1.6 compatable stuff!

_parent = 'object'

function Object:init(modem, id, bcast, rep)
  self.id = id or os.getComputerID()
  self.bcast_id = bcast or 65535
  self.repeat_id = rep or 65533

  self.modem = modem

  self.hostnames = {}

  self:subscribe(
  function(sender, msg, dist)
    if msg.sType and msg.sType == "lookup" then
      local pro = self.hostnames[msg.sProtocol]

      if pro ~= nil and (pro == msg.sHostname or msg.sHostname == nil) then
        self:send(sender, {
          sType = "lookup response",
          sHostname = pro,
          sProtocol = msg.sProtocol,
			  }, "dns")
      end
    end
  end, "dns")
end

function Object:is_open()
  return self.modem:is_open(self.id) and self.modem:is_open(self.bcast_id)
end

function Object:open()
  self.modem:open(self.id)
  self.modem:open(self.bcast_id)
end

function Object:close()
  self.modem:close(self.id)
  self.modem:close(self.bcast_id)
end

function Object:subscribe(cback, proto)
  self.modem.pump:subscribe('network.modem.recv',
  function(_, id, sender, dest, msg, dist)
    if id == self.modem.id then
      if dest == self.bcast_id or dest == self.id
      or (msg.nRecipient and msg.nRecipient == self.id) then
	if not proto or msg.sProtocol == proto then
	  cback(sender, msg.message, proto)
	end
      end
    end
  end)
end

function Object:send(dest, msg, proto)
  local msg_id = math.random( 1, 2147483647 )

  local message = {
    nMessageID = msg_id,
    nRecipient = dest,
    message = msg,
    sProtocol = proto
  }

  self.modem:transmit(dest, self.id, message)
  self.modem:transmit(self.repeat_id, self.id, message)
end

function Object:host(proto, host)
  if type(host) ~= "string" or type(proto) ~= "string" then
    error("Expected: String, string", 2)
  end

  if host == "localhost" then
    error("Reserved hostname", 2)
  end

  if self:lookup(proto, host) ~= nil then
    error("Host Taken", 2)
  end

  self.hostnames[proto] = host
end

function Object:unhost(proto)
  if type(proto) ~= "string" then
    error("Expected: string")
  end

  self.hostnames[proto] = nil
end

function Object:lookup(proto, host)
  self:broadcast({
    sType = "lookup",
    sProtocol = proto,
    sHostname = host,
		 }, "dns")

  local msgs = 0

  local results = {}

  local stop = os.clock() + 2.5

  while os.clock() < stop do
    local sender, msg, proto = self:receive("dns", 0.5)

    if proto == "dns" and msg.sType == "lookup response" then
      table.insert(results, sender)
    end
  end

  return unpack(results)
end

function Object:receive(proto, timeout)
  local timer = os.startTimer(timeout or 0.5)

  while true do
    local evt, p1, p2, p3, p4, p5 = os.pullEvent()

    if evt == "timer" and p1 == timer then
      return nil
    elseif evt == "modem_message" and p1 == self.modem.side then
      if p2 == self.id or p2 == self.bcast_id then
        if p4.sProtocol and p4.sProtocol == proto then
          return p3, p4.message, p4.sProtocol
        end
      end
    end
  end

  return nil
end

function Object:broadcast(msg, proto)
  self:send(self.bcast_id, msg, proto)
end
