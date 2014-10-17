-- lint-mode: api

-- Loading entrypoint for highbeam
os.loadAPI("__LIB__/kidven/kidven")
os.loadAPI("__LIB__/kvio/kvio")

os.loadAPI("__LIB__/thread")

-- Back-end stuff.

local indexers = {}
local importers = {}

for _, file in ipairs(fs.list("__LIB__/highbeam/objects")) do
  kidven.load("Object", "hb-" .. file, "__LIB__/highbeam/objects/" .. file)
end

-- Indexes the data for faster lookup.

for _, file in ipairs(fs.list("__LIB__/highbeam/indexers")) do
  kidven.load("Indexer", "hb-indexer-" .. file,
      "__LIB__/highbeam/indexers/" .. file)
  indexers[#indexers + 1] = file
end

-- Gets the data into the DB

for _, file in ipairs(fs.list("__LIB__/highbeam/importers")) do
  kidven.load("Importer", "hb-importer-" .. file,
      "__LIB__/highbeam/importers/" .. file)
  importers[#importers + 1] = file
end

-- Checks for highbeam plugins in __LIB__/foo/highbeam

for _, file in ipairs(fs.list("__LIB__")) do
  file = fs.combine("__LIB__", file)

  if fs.isDir(file) then
    if fs.isDir(fs.combine(file, "highbeam")) then
      if fs.exists(fs.combine(file, "highbeam/importer")) then
        local ok, err = pcall(function() kidven.load("Importer", "hb-importer-" .. fs.getName(file), fs.combine(file, "highbeam/importer")) end)

        if ok then
          importers[#importers + 1] = fs.getName(file)
        else
          printError("Error loading highbeam extension: " .. file .. "\n" .. err)
        end
      end

        if fs.exists(fs.combine(file, "highbeam/indexer")) then
          local ok, err = pcall(function()
            kidven.load("Indexer", "hb-indexer-" .. fs.getName(file), fs.combine(file, "highbeam/indexer"))
          end)
          if ok then
            indexers[#indexers + 1] = fs.getName(file)
          else
            printError("Error loading highbeam extension: " .. file .. "\n" .. err)
          end
        end
    end
  end
end

-- API for getting highbeam indexers and importers.

function get_indexers()
  return indexers
end

function get_importers()
  return importers
end
