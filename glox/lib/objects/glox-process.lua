-- lint-mode: glox-object

_parent = "object"

local lua_apis = {
  -- APIs.
  'coroutine',
  'table',
  'string',
  'math',
  -- Functions.
  'pairs', 'ipairs', 'unpack', 'next', 'select',
  'error', 'pcall', 'assert',
  'type',
  'getfenv', 'setfenv',
  'getmetatable', 'setmetatable',
  'rawset', 'rawget',

  'loadstring',
  'tonumber', 'tostring',

  'sleep',
}

function Object:init(app, cmdLine, term)
  self.app = app
  self.icon = new('veek-image', new('veek-file', "__LIB__/glox/res/icons/program"):read())

  self.plugins = {}

  self.env = {
    term = {
      native = function() return term end,
    },
  }
  -- TODO: Should these be reloadable seperate?
  for _, plug in ipairs(glox.get_plugins("process")) do
    table.insert(self.plugins, new('glox-process-plugin-' .. plug, app, self))
  end

  self.cmdLine = cmdLine

  self:prepare_env()

  self.id = app.pool:new(function()
    local ok, err = pcall(function()
      self.env.shell.run(cmdLine)
    end)

    if not ok then
      term.clear()
      term.setCursorPos(1, 1)
      printError(err)
    end
  end, self, { terminal = term, has_queue = true })

  self.windows = {}
end

function Object:prepare_env()
  self.env._G = self.env

  self.env.huaxn = huaxn
  self.env.deun = deun

  self.env.fs = fs
  self.env.http = http

  self.env.rs = rs
  self.env.redstone = rs
  self.env.peripheral = peripheral -- TODO: This should probably be sandboxed.

  for _, api in ipairs(lua_apis) do
    self.env[api] = _G[api]
  end

  function self.env.loadfile(path)
    local f = huaxn.open(path, "r")
    if f then
      local func, err = loadstring(f.readAll(), huaxn.getName(path))
      f.close()

      if func then
        setfenv(func, self.env)
      end

      return func, err
    end

    return nil, "No such file."
  end

  function self.env.dofile(path, ...)
    local func, err = self.env.loadfile(path)

    if func then
      setfenv(func, getfenv(2))
      return func()
    else
      error(err, 2)
    end
  end

  -- Install plugin-specified APIs.
  for _, plugin in ipairs(self.plugins) do
    plugin:env(self.env)
  end
end

-- thread-pool hooks.

function Object:started()
  self.running = true

  for _, plugin in ipairs(self.plugins) do
    plugin:started()
  end
end

function Object:die()
  -- TODO: Error reporting somewhere?
  self.app.event_loop:trigger("glox.process.exit", self.id)

  for _, win in ipairs(self.windows) do
    self.app:remove(win)
  end

  self.running = false

  for _, plugin in ipairs(self.plugins) do
    plugin:stopped()
  end
end

function Object:yield()
  for _, plugin in ipairs(self.plugins) do
    plugin:paused()
  end

  self.app:draw()
end

-- Event API
function Object:queue_event(evt, ...)
  self.app.pool:queue_event(self.id, evt, ...)
end
