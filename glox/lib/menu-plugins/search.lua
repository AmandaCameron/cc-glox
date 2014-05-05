os.loadAPI("__LIB__/highbeam/highbeam")

_parent = 'mb-plugin'

function Plugin:init(app, menubar)
	self.mb_plugin:init('?', app, menubar)

	self.mb_plugin.colour_fg = 'glox-menubar-launcher-fg'
	self.mb_plugin.colour_bg = 'glox-menubar-launcher-bg'

	self.timer_id = os.startTimer(300)

	app:subscribe("event.timer", function(_, id)
		if id == self.timer_id then
			app.pool:new(function()
				self:index()

				self.timer_id = os.startTimer(300)
			end)
		end
	end)

	self:build_search()
end

function Plugin:is_expandable()
	return self.indexing
end

function Plugin:clicked(button)
	self:search()
end

function Plugin:index()
	self.progress:set_progress(0)

	self.mb_plugin.colour_fg = 'glox-search-indexing-fg'
	self.mb_plugin.colour_bg = 'glox-search-indexing-bg'

	self.indexing = true
	self.db:scan()
	self.indexing = false

	self.mb_plugin.colour_fg = 'glox-menubar-launcher-fg'
	self.mb_plugin.colour_bg = 'glox-menubar-launcher-bg'
	self.progress:set_progress(1)
end

function Plugin:details()
	return "Currently Indexing..."
end

function Plugin:search()
	self.mb_plugin.app:add(self.search_dialog)
	self.mb_plugin.app:select(self.search_dialog)
end

function Plugin:build_search()
	self.search_dialog = new('agui-container', self.mb_plugin.menubar.agui_widget.width - 14, 2,
		15, self.mb_plugin.app.agui_app.main_window.gooey.agui_widget.height - 1)

	local search = new('agui-search', 15, self.mb_plugin.app.agui_app.main_window.gooey.agui_widget.height - 2)

	self.mb_plugin.app:subscribe('gui.search.selected', function(_, id, selection)
		if id == search.agui_widget.id then
			self.mb_plugin.app:remove(search)

			self.mb_plugin.app:open(selection.command.uri, selection.command.mime)
		end
	end)

	self.mb_plugin.app:subscribe('gui.search.input', function(_, id, input)
		if id == search.agui_widget.id then
			if input ~= '' then
				-- Search all of HighBeam
				local results = self.mb_plugin.app.highbeam:query(input)

				for _, res in ipairs(results) do
					local name = res.meta.name

					if not name then
						name = res.uri
					end

					local mime = res.meta.mime

					if not mime then
						mime = "x-unknown/unknown"
					end

					search.results:add(new('glox-hb-result', name, '', {
						uri = res.uri, 
						mime = mime,
					}))
				end
			end
		end
	end)

	local old_blur = search.blur

	function search.blur(...)
		old_blur(...)

		self.mb_plugin.app:remove(self.search_dialog)
	end

	self.progress = new('agui-progress-bar', 1, self.mb_plugin.app.agui_app.main_window.gooey.agui_widget.height - 1, 15)

	self.search_dialog:add(search)
	self.search_dialog:add(self.progress)
end
