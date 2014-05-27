_parent = 'mb-plugin'

function Plugin:init(app, menubar)
	self.mb_plugin:init('?', app, menubar)

	self.mb_plugin.colour_fg = 'glox-menubar-launcher-fg'
	self.mb_plugin.colour_bg = 'glox-menubar-launcher-bg'

	self:build_search()
end

function Plugin:clicked(button)
	self:search()
end

function Plugin:macro(key)
	if key == keys.space then
		self:search()

		return true
	end
end

function Plugin:search()
	self.mb_plugin.app.pool:new(function()
		-- Sleep shortly to work out some bugs.
		sleep(0.05)

		self.mb_plugin.app:add(self.search_dialog)
		self.mb_plugin.app:select(self.search_dialog)

		self.mb_plugin.app:draw()
	end)
end

function Plugin:build_search()
	self.search_dialog = new('agui-container', self.mb_plugin.menubar.agui_widget.width - 25, 2,
		26, self.mb_plugin.app.agui_app.main_window.gooey.agui_widget.height - 1)

	local search = new('glox-hb-search', 26, self.mb_plugin.app.agui_app.main_window.gooey.agui_widget.height - 1)

	if not pocket then
		search.agui_widget.x = 2

		self.search_dialog.agui_widget.x = self.mb_plugin.menubar.agui_widget.width - 26
		self.search_dialog.agui_widget.width = 27
		self.search_dialog:add(new('agui-virt-seperator', 1, 1, self.search_dialog.agui_widget.height))
	end

	self.mb_plugin.app:subscribe('gui.search.selected', function(_, id, selection)
		if id == search.agui_widget.id then
			if selection:is_a('glox-hb-result') then
				self.mb_plugin.app:remove(search)

				self.mb_plugin.app:open(selection.result.uri,
				 	selection.result.meta['mime-type'] or "unknown/x-unknown")
			elseif selection:is_a('glox-hb-category') then
				search.agui_search.input_box.value = 'type:' .. selection.type

				search.agui_widget:trigger('gui.search.input', 'type:' .. selection.type)
			end
		end
	end)

	self.mb_plugin.app:subscribe('gui.search.input', function(_, id, input)
		if id == search.agui_widget.id then
			search:clear()

			if input ~= '' then
				-- Search all of HighBeam
				local results = self.mb_plugin.app.highbeam:query(input)

				for _, res in ipairs(results) do
					search:add_result(res)
				end
			end
		end
	end)

	local old_blur = search.blur

	function search.blur(...)
		old_blur(...)

		self.mb_plugin.app:remove(self.search_dialog)
	end

	self.search_dialog:add(search)
end
