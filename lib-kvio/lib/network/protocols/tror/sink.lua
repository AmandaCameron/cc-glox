-- lint-mode: kidven

-- TRoR Sink class.

function Object:init(channel, term)
	self.channel = channel
	self.term = term

	self.channel:subscribe(function(source, msg)
		self:on_recv(source, msg)
	end)
end

function Object:on_recv(source, msg)
	local idx = msg:find(':.+;')

	local cmd = msg:sub(1, idx)
	local arg = msg:sub(idx + 2)

	if cmd == "TS" then
		self.term.scroll(tonumber(arg))
	elseif cmd == "TW" then
		self.term.write(arg)
	elseif cmd == "TE" then
		self.term.clear()
	elseif cmd == "TL" then
		self.term.clearLine()
	elseif cmd == "TB" then
		self.term.setCursorBlink(arg == "true")
	elseif cmd == "TK" then
		self.term.setBackgroundColour(tonumber(arg))
	elseif cmd == "TF" then
		self.term.setTextColour(tonumber(arg))
	elseif cmd == "TG" then
		local x, y = term.getCursorPos()
		self.channel:send("TI", x .. "," .. y)
	elseif cmd == "TD" then
		local w, h = term.getSize()
		self.channel:send("TI", w .. "," .. h)
	elseif cmd == "TA" then
		self.channel:send("TI", self.term.isColour() and "true" or "false")
	else
		-- TODO: Something about invalid commands?
	end
end
