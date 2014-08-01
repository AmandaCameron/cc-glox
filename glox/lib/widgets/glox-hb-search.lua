-- lint-mode: glox-widget

-- Glox HighBeam Search widget.

_parent = 'agui-search'

function Widget:init(hb, ...)
  self.agui_search:init(...)

  self.agui_search.input_box.agui_widget.fg = 'glox-highbeam-input--fg'
  self.agui_search.input_box.agui_widget.bg = 'glox-highbeam-input--bg'

  self.agui_search.results.agui_widget.fg = 'glox-highbeam-results--fg'
  self.agui_search.results.agui_widget.bg = 'glox-highbeam-results--bg'

  self.results = {}
  self.hb = hb
end

function Widget:clear()
  self.results = {}

  self:reflow()
end

function Widget:add_result(res)
  self.results[#self.results + 1] = res

  self:reflow()
end


function Widget:reflow()
  self.agui_search.results:clear()

  local categories = {
    other = {}
  }

  local order = {
    'program',
    'file',
    'folder',
    'mount'
  }

  for _, res in ipairs(self.results) do
    local category

    if res.meta.type then
      if not categories[res.meta.type] then
        categories[res.meta.type] = {}

        local found = false

        for _, c in ipairs(order) do
          if c == res.meta.type then
            found = true

            break
          end
        end

        if not found then
          order[#order + 1] = res.meta.type
        end
      end

      category = categories[res.meta.type]

    else
      category = categories["other"]
    end

    category[#category + 1] = res
  end

  order[#order + 1] = "other"

  for _, name in ipairs(order) do
    local category = categories[name]

    local data = self.hb:get('hb-type://' .. name)
    local title = name

    if data then
      title = data.meta['name']
    end

    if category and #category > 0 then
      self.agui_search.results:add(new('glox-hb-category', name, title))

      for _, res in ipairs(category) do
        self.agui_search.results:add(new('glox-hb-result', res))
      end
    end
  end
end
