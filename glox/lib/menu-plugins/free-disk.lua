-- lint-mode: glox

-- Shows the free disk space in the menubar panel.

_parent = "mb-plugin"

function Plugin:init(app, menu)
  self.mb_plugin:init('!', app, menu)

  self.mb_plugin.colour_fg = 'red'

  self.warnings = {}

  app.pool:new(
  function()
    while true do
      self:check()

      sleep(600)
    end
  end)
end

function Plugin:check()
  local fs = fs

  local mounts = {}

  for _, res in ipairs(self.mb_plugin.app.highbeam:query("type:mount")) do
    mounts[res.meta['path']] = {
      in_use = tonumber(res.meta['size']),
      free = tonumber(res.meta['free-space']),
      name = res.meta["name"],
    }

    mounts[res.meta['path']].total = mounts[res.meta['path']].in_use + mounts[res.meta['path']].free
  end

  self.warnings = {}

  for drive, data in pairs(mounts) do
    if data.in_use / data.total then
      table.insert(self.warnings, data.name)
    end
  end
end

function Plugin:is_expandable()
  return true
end

function Plugin:is_visible()
  return #self.warnings > 0
end

function Plugin:details()
  return "Low Space On: " .. table.concat(self.warnings, ", ")
end

function Plugin:clicked(btn)
  -- TODO: Should pop up a file explorer of some kind to allow deletion of files.
end
