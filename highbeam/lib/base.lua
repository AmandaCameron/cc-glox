-- lint-mode: api

-- Loading entrypoint for highbeam
os.loadAPI("__LIB__/kidven/kidven")
os.loadAPI("__LIB__/kvio/kvio")

-- Back-end stuff.

for _, file in ipairs(fs.list("__LIB__/highbeam/objects")) do
  kidven.load("Object", "hb-" .. file, "__LIB__/highbeam/objects/" .. file)
end

-- Indexes the data for faster lookup.

for _, file in ipairs(fs.list("__LIB__/highbeam/indexers")) do
  kidven.load("Indexer", "hb-indexer-" .. file,
      "__LIB__/highbeam/indexers/" .. file)
end

-- Gets the data into the DB

for _, file in ipairs(fs.list("__LIB__/highbeam/importers")) do
  kidven.load("Importer", "hb-importer-" .. file,
      "__LIB__/highbeam/importers/" .. file)
end
