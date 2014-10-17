-- lint-mode: glox-highbeam

-- Indexes based on type of entry.

_parent = "hb-indexer"

function Indexer:init(db)
  self.hb_indexer:init(db)

  self.types = {}
  self.names = {}
end

-- Indexing

function Indexer:pre_scan()
  self.types = {}
  self.names = {}
end

function Indexer:post_scan()
  -- Does Nothing.
end

function Indexer:index(id, entry)
  if entry.meta.type then
    if not self.types[entry.meta.type] then
      self.types[entry.meta.type] = {}
    end

    self.types[entry.meta.type][id] = true
  end

  if entry.meta.name then
    if not self.names[entry.meta.name] then
      self.names[entry.meta.name] = {}
    end

    table.insert(self.names[entry.meta.name], id)
  end
end

function Indexer:delete(id)
  -- TODO.
end

-- Searching

function Indexer:filters()
  return {
    "type",
    "name",
  }
end

function Indexer:lookup(filter, query)
  local results = {}

  if filter == "type" then
    if self.types[query] then
      for k, _ in pairs(self.types[query]) do
        table.insert(results, k)
      end
    end
  elseif filter == "name" then
    for name, data in pairs(self.names) do
      if name:sub(1, #query) == query then
        for _, id in ipairs(data) do
          table.insert(results, id)
        end
      end
    end
  end

  return results
end

function Indexer:load(db)
  local types = db:open("index/type", "r")

  for line in types:lines() do
    if line ~= "" then
      self.types[line] = {}

      local f = db:open("index/type." .. line, "r")

      for entry in f:lines() do
        if entry ~= "" then
          self.types[line][entry] = true
        end
      end

      f:close()
    end
  end

  types:close()

  local names = db:open("index/names", "r")

  for line in names:lines() do
    if line ~= "" then
      local name = line:match("^([^:]+): ")
      self.names[name] = {}

      for id in line:sub(#name + 4):gmatch('([^ ])') do
        table.insert(self.names[name], id)
      end
    end
  end

  names:close()
end

function Indexer:save(db)
  local types = db:open("index/type", "w")

  for type, data in pairs(self.types) do
    types:write_line(type)

    local f = db:open("index/type." .. type, "w")

    for entry, _ in pairs(data) do
      f:write_line(entry)
    end

    f:close()
  end

  types:close()


  local names = db:open("index/names", "w")

  for name, data in pairs(self.names) do
    names:write_line(name .. ": " .. table.concat(data, " "))
  end

  names:close()
end
