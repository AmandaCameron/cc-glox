-- lint-mode: kidven

-- Chat Protocol, using Dan200's CC1.6 protocol

_parent = "object"

function Object:init(channel)
  self.channel = channel

  self.id = math.random(1, 2147483647)

  self.channel:subscribe(function(sender, msg, dist)
    if msg.sType and msg.sType == "ping to client" then
      self.channel:send({
        sType = "pong to server",
        nUserID = self.id,
      })
    end
  end)
end

function Object:on_text(fn)
  self.channel:subscribe(function(sender, msg, dist)
    if msg.sType and msg.sType == "text" then
      fn(msg.sText)
    end
  end)
end

function Object:say(text)
  self.channel:send({
    sType = "chat",
    sText = text,
    nUserID = self.id
  })
end

function Object:disconnect()
  self.channel:send({
    sType = "logout",
    nUserID = self.id
  })
end
