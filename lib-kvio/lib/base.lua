-- lint-mode: api

os.loadAPI("__LIB__/kidven/kidven")
os.loadAPI("__LIB__/kvutils/kvutils")

for _, file in ipairs(fs.list("__LIB__/kvio/objects")) do
	kidven.load("Object", "kvio-" .. file, "__LIB__/kvio/objects/" .. file)
end
