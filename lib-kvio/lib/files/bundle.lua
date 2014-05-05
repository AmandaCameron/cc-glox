-- Bundle File object for CC

_parent = 'object'

local SEP_LENGTH = 16

function Object:init(fname)
  self.fname = fname

  self.index = {}
  self.data = {}
end

function Object:free_memory()
  self.index = {}
  self.data = {}
end

function Object:load()
  self.index = {}
  self.data = {}

  local f = fs.open(self.fname, "r")

  if not f then
     return
  end

  local sep = f.readLine()

  local line = f.readLine()

  while line do
    local file = {
      name = "",
      props = {},
      contents = {},
    }

    -- Read the Other header stuff.
    while line ~= sep do
      local name, value = line:match("^([^:]+): (.+)$")

      if name ~= nil then
        if name == "Name" then
          file.name = value
        else
          file.props[name] = value
        end
      end

      line = f.readLine()
    end

    line = f.readLine()

    while line ~= sep do
      table.insert(file.contents, line)

      line = f.readLine()
    end


    table.insert(self.data, file)
    self.index[file.name] = #self.data

    line = f.readLine()
  end
end

function Object:save()
  local sep = "--"

  while #sep < SEP_LENGTH do
    local i = math.floor(math.random(1, 16))
    sep = sep .. ("0123456789ABCDEF"):sub(i, i)
  end

  sep = sep .. "--"

  -- Write the actual data!

  local f = fs.open(self.fname, 'w')

  f.write(sep .. "\n")

  for _, file in ipairs(self.data) do
    f.write('Name: ' .. file.name .. "\n")

    for name, value in pairs(file.props) do
      f.write(name .. ": " .. value .. "\n")
    end

    f.write(sep .. "\n")

    for _, line in ipairs(file.contents) do
      f.write(line .. "\n")
    end

    f.write(sep .. "\n")
  end

  f.close()
end

function Object:open(path, mode)
  if mode == "w" then
    local handle =  new('kvio-memory-writer', function(contents)
      local lines = {}

      local pos = 0

      for line in contents:gmatch("(.+)\n") do
        table.insert(lines, line)
        pos = pos + #line + 1
      end

      table.insert(lines, contents:sub(pos)) -- Haaaack

      local file = { name = path, contents = lines, props = {} }
      
      if self.index[path] then
        self.data[self.index[path]] = file
      else
        table.insert(self.data, file)
        self.index[path] = #self.data
      end
    end)

    return handle
  elseif mode == "r" then
    local ind = self.index[path]

    if not ind then
      return nil
    end

    local handle = new('kvio-memory-reader', self.data[ind].contents)

    return handle
  elseif mode == "a" then
    local handle = self:open(path, 'w')

    if not self.index[path] then
      return handle
    end

    for _, line in ipairs(self.data[self.index[path]].contents) do
      handle:write_line(line)
    end

    return handle
  else
    error("Invalid Mode", 2)
  end
end

function Object:files()
  return pairs(self.index)
end

function Object:exists(path)
  return self.index[path] ~= nil
end

function Object:get_prop(path, prop)
  return self.index[path].props[prop]
end

function Object:set_prop(path, prop)
  return self.index[path].props[prop]
end

-- Current version of the data format does not support directories.
function Object:is_dir(path)
  return false
end
