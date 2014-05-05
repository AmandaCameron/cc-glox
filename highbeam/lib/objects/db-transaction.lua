-- Database Transaction.

_parent = "object"

function Object:init(db)
  self.db = db

  self.objects = {}
end

-- Objects!

function Object:add_object(uri)
  local id = ""

  for _=1,16 do
    local i = math.floor(math.random(1, 36))
    id = id .. ("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"):sub(i, i)
  end

  self.objects[id] = {
    keywords = {},
    meta = {},
    uri = uri,
  }

  return id
end

function Object:add_keyword(id, reference)
  self.objects[id].keywords[reference] = true
end

function Object:add_metadata(id, meta, value)
  if type(value) == "table" then
    error("Table values are illegal for metadata.", 2)
  end

  self.objects[id].meta[meta] = value
end

function Object:commit()
  for id, data in pairs(self.objects) do
    local new_data = {
      keywords = {},
      meta = data.meta,
      uri = data.uri,
      id = id,
    }

    for ref, _ in pairs(data.keywords) do
      table.insert(new_data.keywords, ref)
    end

    self.db:_insert(id, new_data)
  end
end