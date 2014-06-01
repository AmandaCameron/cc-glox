-- lint-mode: glox-widget

_parent = 'agui-window'

function Widget:init(app)
	self.agui_window:init('Run...', 20, 6)

	self.app = app

	local search = new('glox-program-picker', self.app, 18, 4)
	search.agui_widget.x = 2
	search.agui_widget.y = 2

	self:add(search)

	self.app:subscribe('glox.progpicker.selected', function(_, id, _)
		if id == search.agui_widget.id then
			self.app:launch(search.agui_search.input_box.value)
		end
	end)
end

function Widget:blur()
	self.app:remove(self)
end
