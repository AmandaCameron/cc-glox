-- HighBeam Connection Shim.

function Object:init()
  if deun then
    self.database = deun.get('highbeam')
    self.remote = true
  end

  if not self.database then
    self.database = new('hb-database')
    self.database:load()
    
    self.remote = false
  end
end

function Object:query(input)
  return self.database:query(input)
end

function Object:get(uri)
  return self.database:get(uri)
end

function Object:scan()
  return self.database:scan()
end