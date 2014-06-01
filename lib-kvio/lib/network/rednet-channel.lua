-- lint-mode: kidven

-- Acts as a kvio-channel for rednet comms.

_parent = 'kvio-channel'

function Object:init(rednet, comp, proto)
  kidven.verify({ rednet, comp }, 'kvio-rednet', 'number')

  self.proto = proto
  self.target = comp
  self.rednet = rednet

  self.id = 'rednet-' .. self.rednet.id .. '-' .. self.target
end

function Object:subscribe(handler)
  self.rednet:subscribe(
  function(sender, msg)
    if sender == self.target then
      handler(sender, msg, -1)
    end
  end)
end

function Object:send(msg)
  self.rednet:send(self.target, msg, self.proto)
end
