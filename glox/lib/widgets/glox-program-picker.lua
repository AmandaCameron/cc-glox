-- lint-mode: glox

_parent = 'veek-search'

function Widget:init(app, w, h)
	self.veek_search:init(w, h)

	self.app = app

	self.ready_go = false
	self.command = ''

	self.app:subscribe('gui.search.input', function(_, id, value)
		self.command = value

		local idx = value:find(' ')
		if idx then
			self.ready_go = true

			self.veek_search.results:add(new('veek-list-item', 'Launch ' .. value:sub(1, idx)))
		else
			for _, prog in ipairs(self.app.shell.programs()) do
				if prog:match(value) then
					self.veek_search.results:add(new('veek-list-item', prog))
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
	self.veek_search.input_box.value = ''
	self.veek_search.results:clear()

	self.veek_container:focus()
end
