-- lint-mode: glox-widget

-- Glox HighBeam Search widget.

_parent = 'veek-search'

function Widget:init(...)
  self.veek_search:init(...)

  self.veek_search.input_box.veek_widget.fg = 'glox-highbeam-input--fg'
  self.veek_search.input_box.veek_widget.bg = 'glox-highbeam-input--bg'

  self.veek_search.results.veek_widget.fg = 'glox-highbeam-results--fg'
  self.veek_search.results.veek_widget.bg = 'glox-highbeam-results--bg'

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
  self.veek_search.results:clear()

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
      self.veek_search.results:add(new('glox-hb-category', name, title))

      for _, res in ipairs(category) do
        self.veek_search.results:add(new('glox-hb-result', res))
      end
    end
  end
end
