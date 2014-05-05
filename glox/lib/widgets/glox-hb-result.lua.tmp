_parent = 'agui-list-item'

function Widget:init(name, source, cmd)
	self.agui_list_item:init(name)

	self.name = name
	self.source = source
	self.command = cmd
end

function Widget:draw(c)
	c:move(1, 1)
	c:write(string.rep(" ", c.width))

	c:move(1, 1)
	c:write(self.name)

	c:move(c.width - #self.source, 1)
	c:write(self.source)
end
