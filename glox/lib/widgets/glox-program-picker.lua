-- lint-mode: glox

_parent = 'agui-search'

function Widget:init(app, w, h)
	self.agui_search:init(w, h)

	self.app = app

	self.ready_go = false
	self.command = ''

	self.app:subscribe('gui.search.input', function(_, id, value)
		self.command = value

		local idx = value:find(' ')
		if idx then
			self.ready_go = true

			self.agui_search.results:add(new('agui-list-item', 'Launch ' .. value:sub(1, idx)))
		else
			for _, prog in ipairs(self.app.shell.programs()) do
				if prog:match(value) then
					self.agui_search.results:add(new('agui-list-item', prog))
				end
			end
		end
	end)

	self.app:subscribe('gui.search.selected', function(_, id, sel)
		if self.ready_go then
			self:trigger('glox.progpicker.selected', self.command)
		end
	end)
end

function Widget:focus()
	self.agui_search.input_box.value = ''
	self.agui_search.results:clear()

	self.agui_container:focus()
end
