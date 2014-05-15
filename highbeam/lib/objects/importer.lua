-- Highbeam Importer meta-class

-- Banned words for automatic keyword-ing

local banned_words = {
  ["if"] = true,
  ["and"] = true,
  ["or"] = true,

  the = true,
  my = true,
  your = true,
  i = true,
}

-- Actual Methods.

_parent = "object"

function Object:init(db, env, name)
  self.db = db
  self.env = env
end

function Object:transaction()
  return self.db:transaction()
end

function Object:import()
  error("This should be implemented", 2)
end


-- Helpers for scanning common formats.

function Object:scan(trans, id, all)
  for word in all:gmatch("[^\n \t]+") do
    if not banned_words[word:lower()] then
      trans:add_keyword(id, word:lower())
    end
  end
end

function Object:scan_file(trans, id, fname)
  local f = fs.open(fname, "r")
  local all = f.readAll()
  f.close()

  self:scan(trans, id, all)
end