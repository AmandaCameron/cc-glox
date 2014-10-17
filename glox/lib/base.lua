-- lint-mode: api

os.loadAPI("__LIB__/veek/veek")

os.loadAPI("__LIB__/kvutils/kvutils")
os.loadAPI("__LIB__/ciiah/ciiah")
os.loadAPI("__LIB__/huaxn/huaxn")

os.loadAPI("__LIB__/kvio/kvio")

veek.load_api("__LIB__/veek/gui")
veek.load_api("__LIB__/veek/images")

rawset(_G, "fs", huaxn)

for _, fname in ipairs(fs.list("__LIB__/glox/widgets/")) do
  kidven.load("Widget", fname, "__LIB__/glox/widgets/" .. fname)
end

for _, fname in ipairs(huaxn.list("__LIB__/glox/objects/")) do
  kidven.load("Object", fname, "__LIB__/glox/objects/" .. fname)
end

-- Plugins!

local plugin_dirs = {
	menubar = '__LIB__/glox/menu-plugins',
  process = '__LIB__/glox/process-plugins',
}

function get_plugins(category)
	if plugin_dirs[category] then
		return huaxn.list(plugin_dirs[category])
	end

	return {}
end

for type, dir in pairs(plugin_dirs) do
  for _, fname in ipairs(huaxn.list(dir)) do
    kidven.load("Plugin", 'glox-' .. type .. '-plugin-' .. fname,
        huaxn.combine(dir, fname))
  end
end
