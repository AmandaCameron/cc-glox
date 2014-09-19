-- lint-mode: glox-widget

_parent = 'veek-window'

function Widget:init(app)
	self.veek_window:init('Run...', 20, 6)

	self.app = app

	local search = new('glox-program-picker', self.app, 18, 4)
	search.veek_widget.x = 2
	search.veek_widget.y = 2

	self:add(search)

	self.app:subscribe('glox.progpicker.selected', function(_, id, _)
		if id == search.veek_widget.id then
			self.app:launch(search.veek_search.input_box.value)
		end
	end)
end

function Widget:blur()
	self.app:remove(self)
end
