-- TROR Source Class.

function Object:init(channel)
	self.width = -1
	self.height = -1

	self:send("TD", "")

	self.x = 1
	self.y = 1

	self.is_colour = false

	self.channel = channel
	self.channel:subscribe(function(source, msg) self:on_recv(source, msg) end)
end

-- Networking functions.

function Object:send(cmd, args)
	self.channel:send(cmd .. ":;" .. args)
end

function Object:on_recv(source, msg)
	local idx = msg:find(':')

	local cmd = msg:sub(1, idx)
	local arg = msg:sub(msg:sub(idx):find(":") + 1)

	if cmd == "TI" then
		if self.state == 0 then
			idx = arg:find(',')

			local w = tonumber(arg:sub(1, idx))
			local h = tonumber(arg:sub(idx + 1))

			self.width = w
			self.height = h

			self.state = 1

			self:send("TA", "")
		elseif self.state == 1 then
			self.is_colour = arg == "true"

			self.state = 2

			self:send("TG")
		elseif self.state == 2 then
			idx = arg:find(',')

			local x = tonumber(arg:sub(1, idx))
			local y = tonumber(arg:sub(idx + 1))

			self.x = x
			self.y = y

			self.state = 3	
		end
	end
end

-- Am I ready for drawing on?

function Object:ready()
	return self.state == 3
end

-- Canvas-alike functions

function Object:size()
	return self.width, self.height
end

function Object:pos()
	return self.x, self.y
end

function Object:write(txt)
	self:send("TW", txt)
	self.x = self.x + #txt
end

function Object:move(x, y)
	self.x = x
	self.y = y

	self:send("TC", x .. "," .. y)
end

function Object:clear()
	self:send("TE", "")
end

function Object:clear_line()
	self:send("TL", "")
end

function Object:set_cursor(x, y, blink)
	self:move(x, y)
	self:send("TB", blink and "true" or "false")
end

function Object:set_fg(colour)
	self:send("TF", colour .. "")
end

function Object:set_bg(colour)
	self:send("TK", colour .. "")
end

function Object:scroll(lines)
	self:send("TS", lines .. "")
end

-- Wrap me, baby!


function Object:as_redirect()
	local ret = {}

	function ret.write(txt)
		self:write(txt)
	end

	function ret.clear()
		self:clear()
	end

	function ret.setCursorPos(x, y)
		self:move(x, y)
	end

	function ret.setTextColour(clr)
		self:set_fg(clr)
	end

	function ret.setBackgroundColour(clr)
		self:set_bg(clr)
	end

	function ret.setCursorBlink(blink)
		self.blink = blink
	end

	function ret.scroll(lines)
		self:scroll(lines)
	end

	function ret.isColour()
		return self.is_colour
	end

	function ret.getCursorPos()
		return self:pos()
	end

	function ret.getSize()
		return self:size()
	end


	-- Americans!

	ret.setTextColor = ret.setTextColour
	ret.setBackgroundColor = ret.setBackgroundColour
	ret.isColor = ret.isColour

	return ret
end