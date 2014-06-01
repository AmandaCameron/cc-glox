-- lint-mode: glox

_parent = 'agui-list-item'

function Widget:init(result)
	self.agui_list_item:init()

	self.agui_widget.fg = 'glox-highbeam-result--fg'
	self.agui_widget.bg = 'glox-highbeam-result--bg'

	self.result = result

	self.name = result.meta.name or self.result.uri
end

function Widget:draw(c)
	c:clear()

	c:move(4, 1)
	c:write(self.name)
end
