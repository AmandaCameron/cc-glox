-- HighBeam example search program.

os.loadAPI("__LIB__/agui/agui")
os.loadAPI("__LIB__/highbeam/highbeam")

local app = kidven.new("agui-app")

local input = kidven.new("agui-input", 1, 1, 1)

local layout = kidven.new("agui-layout", app.main_window.gooey)

layout:add(input)
layout:add_anchor(input, "left", "left", -1, 0)
layout:add_anchor(input, "right", "right", -1, 0)
layout:add_anchor(input, "top", "top", -1, 0)

local results = kidven.new("agui-list", 1, 1, 1, 1)

layout:add(results)
layout:add_anchor(results, "left", "left", -1, 0)
layout:add_anchor(results, "right", "right", -1, 0)
layout:add_anchor(results, "top", "bottom", input, 0)
layout:add_anchor(results, "bottom", "bottom", -1, 0)

layout:reflow()

local db = kidven.new("hb-database")

db:load()

app:subscribe("gui.input.submit", function()
  results:clear()

  for _, result in ipairs(db:query("*", input.value)) do
    local name = result.meta["name"] or object

    results:add(kidven.new('agui-list-item', name .. " from " .. result.table))
  end
end)

app:main()