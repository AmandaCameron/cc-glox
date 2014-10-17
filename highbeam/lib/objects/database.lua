-- lint-mode: glox-highbeam

-- lint-ignore-global-get: highbeam

-- HighBeam Database Object.

-- Shamelessly stolen from the 'shell' program:

local function tokenise( ... )
  local sLine = table.concat( { ... }, " " )
  local tWords = {}
  local bQuoted = false
  for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
    if bQuoted then
      table.insert( tWords, match )
    else
      for m in string.gmatch( match, "[^ \t]+" ) do
  table.insert( tWords, m )
      end
    end
    bQuoted = not bQuoted
  end
  return tWords
end

-- Actual database code.

_parent = "kvio-bundle"

function Object:init()
  self.kvio_bundle:init("__LIB__/state/highbeam")

  if not fs.isDir("__LIB__/state/") then
    fs.makeDir("__LIB__/state")
  end

  self.data = {}

  self.indexers = {}
  self.importers = {}
  self.filters = {}

  for _, name in ipairs(highbeam.get_indexers()) do
    local indexer = new("hb-indexer-" .. name, self)
    self.indexers[name] = indexer

    for _, filter in ipairs(indexer:filters()) do
      self.filters[filter] = indexer
    end
  end

  for _, name in ipairs(highbeam.get_importers()) do
    table.insert(self.importers, new('hb-importer-' .. name, self))
  end
end

-- Read/Write the data.

function Object:load()
  self.kvio_bundle:load()

  local idx = self:open("file-index", "r")

  for line in idx:lines() do
    local id = line:match("^([^:]+): ")

    if not id then
      break
    end

    self.data[id] = {
      uri = line:sub(#id + 3),
      meta = {},
      keywords = {},
    }

    local f = self:open("data/" .. id, "r")

    for line in f:lines() do
      local meta = line:match("^([^:]+): ")

      if meta and meta ~= "Keywords" then
        self.data[id].meta[meta] = textutils.unserialize(line:sub(#meta + 3))
      elseif meta then
        self.data[id].keywords = {}

        for keywrd in line:sub(#meta + 3):gmatch("[^,]+") do
          table.insert(self.data[id].keywords, keywrd)
        end
      end
    end
  end

  for idx, idxr in pairs(self.indexers) do
    idxr:load(self)
  end

  -- Clear the memory because we're done with it.
  self.kvio_bundle:free_memory()
end

function Object:save()
  local index = self:open("file-index", "w")

  for id, data in pairs(self.data) do
    index:write_line(id .. ": " .. data.uri)

    local f = self:open("data/" .. id, "w")

    for meta, value in pairs(data.meta) do
      f:write_line(meta .. ": " .. textutils.serialize(value))
    end

    f:write_line("Keywords: " .. table.concat(data.keywords, ","))

    f:close()
  end

  index:close()

  for idx, idxr in pairs(self.indexers) do
    idxr:save(self)
  end

  self.kvio_bundle:save()

  -- Clear the memory, as we're done with it.
  self.kvio_bundle:free_memory()
end


-- Operate on the in-memory data.


function Object:plugins(meth, ...)
  for plugin in ipairs(self.indexers) do
    if plugin[meth] then
      plugin[meth](plugin, ...)
    end
  end
end

function Object:transaction()
  return new('hb-db-transaction', self)
end

-- Do the scan

-- TODO: Limited scope scans.
function Object:scan(env)
  self.data = {}

  for _, idx in pairs(self.indexers) do
    idx:pre_scan()
  end

  local task = new('hb-progress', self, 'Scan')
  local pool = new('thread-pool')

  for i, imp in pairs(self.importers) do
    pool:new(function()
      local ok, err = pcall(function()
        imp:import(task, env)
      end)

      if not ok then
        printError("Error scanning using " .. highbeam.get_importers()[i] .. " -- " .. err)

        sleep(2)
      end
    end)
  end

  pool:main()

  task:done()

  for _, idx in pairs(self.indexers) do
    idx:post_scan()
  end

  self:save()
end

-- Query the data

function Object:query(input)
  local matches = {}

  input = input:lower()

  local query = tokenise(input)

  local kw_res = {}

  for _, word in ipairs(query) do
    kw_res[word] = {}
  end

  -- Iterate over the entire database ONCE.
  for fname, data in pairs(self.data) do
    for _, kw in ipairs(data.keywords) do
      for _, word in ipairs(query) do

        if word == kw then
          -- Don't worry about duplicates, they'll get resolved later on.
          table.insert(kw_res[word], fname)
        end
      end
    end
  end

  local function filter_lookup(word, idx, idx_qry)
    local idx_res = self.filters[idx]:lookup(idx, idx_qry)

    for _, res in ipairs(idx_res) do
      if not matches[res] then
        matches[res] = {}
      end

      matches[res][word] = true
    end
  end

  local function kw_lookup(word)
    for _, res in ipairs(kw_res[word]) do
      if not matches[res] then
        matches[res] = {}
      end

      matches[res][word] = true
    end
  end

  for _, word in ipairs(query) do
    if word:match("^([a-z]+):") then
      local idx = word:match("^([a-z]+):")
      local idx_qry = word:sub(#idx + 2)

      if self.filters[idx] then
        filter_lookup(word, idx, idx_qry)
      else
        kw_lookup(word)
      end
    else
      kw_lookup(word)
    end
  end

  local results = {}

  for result, words in pairs(matches) do
    local full_match = true

    for _, match in ipairs(query) do
      if not words[match] then
        full_match = false
      end
    end

    if full_match then
      table.insert(results, {
        id = result,
        uri = self.data[result].uri,
        meta = self.data[result].meta,
      })
    end
  end

  return results
end

function Object:get(uri)
  for id, data in pairs(self.data) do
    if data.uri == uri then
      return {
        id = id,
        uri = uri,
        meta = data.meta,
      }
    end
  end

  return nil
end

-- Private Data Manupulation.

function Object:_insert(id, entry)
  old = self:get(entry.url)

  if old then
    for key, val in pairs(old.meta) do
      if not entry.meta[key] then
        entry.meta[key] = val
      end
    end

    id = old.id
  end

  for _, idx in pairs(self.indexers) do
    idx:index(id, entry)
  end

  self.data[id] = entry
end

function Object:_delete(id)
  for _, idx in pairs(self.indexers) do
    idx:delete(id)
  end

  self.data[id] = nil
end

-- IPC Notifications.

function Object:notify(evt, ...)
  os.queueEvent("hb-ipc", evt, ...)

  sleep(0.10)
end
