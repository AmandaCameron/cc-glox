-- lint-mode: glox-highbeam

-- Indexes photos by size

_parent = "hb-indexer"

function Indexer:init(db)
  self.hb_indexer:init(db)

  self.data = {}
end

function Indexer:filters()
  return {
    "size",
    "min-size",
    "max-size",

    "width",
    "height",
  }
end

-- Indexing

function Indexer:index(id, entry)
  if entry.meta.type == "image" and entry.meta.dimensions then

    local width, height = entry.meta.dimensions:match("^([%d]+),([%d]+)$")

    self.data[id] = {
      width = tonumber(width),
      height = tonumber(height),
    }
  end
end

function Indexer:delete(id)
  self.data[id] = nil
end

function Indexer:pre_scan()
end

function Indexer:post_scan()
end

-- Searching

function Indexer:lookup(filter, value)
  if filter == "size" then
    return self:filter(function(dimens)
      return (dimens.width .. "," .. dimens.height == value)
    end)
  elseif filter == "min-size" then
    local width, height = value:match("^([%d]+),([%d]+)$")
    width = tonumber(width)
    height = tonumber(height)

    return self.filter(function(dimens)
      return dimens.width > width and dimens.height > height
    end)
  elseif filter == "max-size" then
    local width, height = value:match("^([%d]+),([%d]+)$")
    width = tonumber(width)
    height = tonumber(height)

    return self.filter(function(dimens)
      return dimens.width < width and dimens.height < height
    end)
  elseif filter == "width" then
    return self.filter(function(dimens)
      return dimens.width == tonumber(value)
    end)
  elseif filter == "height" then
    return self.filter(function(dimens)
      return dimens.height == tonumber(value)
    end)
  end
end

function Indexer:filter(func)
  local results = {}

  for id, dimens in pairs(self.data) do
    if func(dimens) then
      table.insert(results, id)
    end
  end

  return results
end

function Indexer:load(db)
  local data = db:open("index/pictures", "r")

  for line in data:lines() do
    if line ~= "" then
      local id, width, height = line:match("^([^:]+): ([%d]+),([%d]+)$")

      self.data[id] = {
        width = tonumber(width),
        height = tonumber(height),
      }
    end
  end

  data:close()
end

function Indexer:save(db)
  local file = db:open("index/pictures", "w")

  for id, dimens in pairs(self.data) do
    file:write_line(id .. ": " .. dimens.width .. "," .. dimens.height)
  end

  file:close()
end
