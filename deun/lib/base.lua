-- lint-mode: api

-- lint-ignore-global-get: deun

-- Deun Base Library.

os.loadAPI("__LIB__/kidven/kidven")
os.loadAPI("__LIB__/event")
os.loadAPI("__LIB__/thread")
os.loadAPI("__LIB__/kvutils/kvutils")


for _, fname in ipairs(fs.list("__LIB__/deun/objects/")) do
  kidven.load("Object", "deun-" .. fname, "__LIB__/deun/objects/" .. fname)
end

local svcs
local gui_svc
local pool

if deun then
  svcs, pool, gui_svc = deun._get_state()
else
  svcs = kidven.new('kvu-set')
  pool = kidven.new('thread-pool')
end

function _get_state()
  return svcs, pool, gui_svc
end

local function start(svc)
  pool:new(function()
    svc:cast('deun-service').state = 'starting'

    svc:trigger('service.start')
    svc:cast('event-loop'):main()
    svc:trigger('service.stop')
  end, svc:cast('deun-service'))
end

function run(shell)
  local has_svcs = false
  for svc in svcs:iter() do
    has_svcs = true
    start(svc)
    print("Starting " .. svc:cast('deun-service').name .. "...")
  end

  local show_term = false

  if gui_svc then
    has_svcs = true
    print("Starting GUI " .. gui_svc:cast("deun-service").name .. "...")
    start(gui_svc)
  else
    pool:new(function()
      print("Launching Shell.")

      shell.run("shell")
    end)
  end

  if has_svcs then
    pool:main()
  else
    print("No Services Installed, Aborting.")
    return
  end

  -- Cleanup!

  term.clear()
  term.setCursorPos(1, 1)

  print("Stopping Services...")

  for svc in iter() do
    print("Stopping " .. svc:cast('deun-service').name .. "...")

    svc:trigger("service.stop")
  end

  if not show_term then
    print("Services Stoepped, shutting down.")
    os.shutdown()
  end
end

-- API.

function add(service)
  svcs:add(service)
end

function add_gui(service)
  gui_svc = service
end

function iter()
  return svcs:iter()
end

function get(svc)
  for s in iter() do
    if s:cast('deun-service').name == svc then
      return s
    end
  end
end
