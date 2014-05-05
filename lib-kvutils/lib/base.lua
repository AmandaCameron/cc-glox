os.loadAPI("__LIB__/kidven/kidven")

for _, file in ipairs(fs.list("__LIB__/kvutils/objects")) do
	kidven.load("Object", "kvu-" .. file, "__LIB__/kvutils/objects/" .. file)
end