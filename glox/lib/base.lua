-- lint-mode: api

os.loadAPI("__LIB__/agui/agui")
os.loadAPI("__LIB__/agui-images/agimages")
os.loadAPI("__LIB__/kvutils/kvutils")
os.loadAPI("__LIB__/ciiah/ciiah")

for _, fname in ipairs(fs.list("__LIB__/glox/widgets/")) do
  kidven.load("Widget", fname, "__LIB__/glox/widgets/" .. fname)
end

for _, fname in ipairs(fs.list("__LIB__/glox/objects/")) do
  kidven.load("Object", fname, "__LIB__/glox/objects/" .. fname)
end

for _, fname in ipairs(fs.list("__LIB__/glox/menu-plugins/")) do
  kidven.load("Plugin", 'mb-plugin-' .. fname, "__LIB__/glox/menu-plugins/" .. fname)
end

-- Plugins!

local plugin_dirs = {
	menubar = '__LIB__/glox/menu-plugins'
}

function get_plugins(category)
	if plugin_dirs[category] then
		return fs.list(plugin_dirs[category])
	end

	return {}
end
