_parent = 'object'

function Object:init(size)
  self.size = size
  self.data = {}
end

function Object:add(value)
  table.insert(self.data, value)
  while #self.data > self.size do
    table.remove(self.data, 1)
  end
end

function Object:clear()
  self.data = {}
end

function Object:iter()
  return ipairs(self.data)
end
