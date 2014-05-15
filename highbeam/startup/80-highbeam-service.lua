-- HighBeam service for servicing servicey stuff.

os.loadAPI("__LIB__/deun/deun")
os.loadAPI("__LIB__/highbeam/highbeam")

local Service = {}

function Service:init()
  self.deun_service:init('highbeam', 'HighBeam Service')

  self.database = kidven.new('hb-database')
  if fs.exists("__LIB__/state/highbeam") then
    self.database:load()
  else
    self:scan()
  end

  self.env = kidven.new('hb-env', shell)

  self:subscribe('event.huaxn-mount', function()
    self:scan()
  end)

  self:subscribe('event.huaxn-unmount', function()
    self:scan()
  end)

  self:subscribe('event.hb-ipc', function(_, cmd, arg)
    if cmd == "scan" then
      os.queueEvent("hb-ipc", "status", "scanning")

      self.deun_service.details = "Scanning..."
      self.database:scan(self.env, arg)
      self.deun_service.details = "Ready."

      os.queueEvent("hb-ipc", "status", "idle")
    end
  end)

  -- Disk auto-indexing.

  self:subscribe('event.disk', function(_, side)
    self:scan(disk.getMountPath(side))
  end)

  self:subscribe('event.disk_eject', function(_, side)
    self:scan()
  end)
end

-- Service Commands

function Service:query(input)
  return self.database:query(input)
end

function Service:get(uri)
  return self.database:get(uri)
end

function Service:scan(scope)
  -- Fire an event that we listen to so we can do
  -- the scanning in the background,
  os.queueEvent("hb-ipc", "scan", scope)
end

kidven.register("deun-highbeam", Service, "deun-service")

deun.add(kidven.new('deun-highbeam'))