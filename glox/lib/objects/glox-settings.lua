_parent = 'object'

function Object:init(app)
  self.data = {
    enable_lob = false,
    enable_plugins = true,
    plugins = {
      menubar = { 'search', 'free-disk', 'highbeam-status' }
    },
    favourites = {
      { 'Shell', 'shell' },
      { 'Settings', 'glox-settings' },
    },
    first_run = true,
  }

  self.app = app
end

function Object:load()
  local f = fs.open('__CFG__/glox/settings', 'r')

  if f then
    local data = textutils.unserialize(f.readAll())

    for k, v in pairs(data) do
      if self.data[k] ~= nil then
      	self.data[k] = v
      end
    end

    f.close()
  end


  if self.app then
    self.app:trigger('glox.settings.commit')
  end
end

function Object:save()
  if not fs.exists("__CFG__/glox") then
    fs.makeDir("__CFG__/glox")
  end

  local f = fs.open('__CFG__/glox/settings', 'w')

  f.write(textutils.serialize(self.data))

  f.close()

  if self.app then
    self.app:trigger('glox.settings.commit')
  end

  os.queueEvent("glox-ipc", "settings_changed")
end

-- Getters

function Object:get_lob()
  return self.data.enable_lob
end

function Object:get_plugins_enabled()
  return self.data.enable_plugins
end

function Object:get_plugins(category)
  return self.data.plugins[category]
end

function Object:get_favourites()
  return self.data.favourites
end

function Object:is_first_run()
  return self.data.first_run
end

-- Setters

function Object:set_onboarded(value)
  self.data.first_run = not value
  
  self:save()
end

function Object:set_plugins_enabled(value)
  self.data.enable_plugins = value
  self:save()
end

function Object:enable_plugin(category, name)
  table.insert(self.data.plugins[category], name)
  self:save()
end

function Object:disable_plugin(category, name)
  local old = self.data.plugins[category]

  self.data.plugins[category] = {}

  for _, plug in ipairs(old) do
    if plug ~= name then
      table.insert(self.data.plugins[category], plug)
    end
  end

  self:save()
end

function Object:add_favourite(label, cmd)
  table.insert(self.data.favourites, { label, cmd })
  self:save()
end

function Object:remove_favourite(label)
  local old = self.data.favourites

  self.data.favourites = {}

  for _, fav in ipairs(old) do
    if fav[1] ~= label then
      table.insert(self.data.favourites, fav)
    end
  end

  self:save()
end
