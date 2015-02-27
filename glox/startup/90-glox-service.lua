-- Starts veek-shell!

os.loadAPI("__LIB__/huaxn/huaxn")
os.loadAPI('__LIB__/glox/glox')
os.loadAPI("__LIB__/deun/deun")

local svc = kidven.new('deun-service', 'glox', 'Graphical Environment powered by Project Veek')

-- Load the first modem we found.
for _, side in ipairs(peripheral.getNames()) do
  if peripheral.getType(side) == "modem" then
    rednet.open(side)

    break
  end
end

local t = term.native

if type(t) == "function" then
  t = t()
end

local app = kidven.new('glox-app', t, shell)


function error_screen(err)
  t.clear()
  t.setCursorPos(1, 1)
  t.write("Fatal error in Glox: " .. err)
end

svc:subscribe('service.start',
function()
  local ok, err = pcall(function()
    app:draw()
    app:main()

    if app.main_err then
      error_screen(app.main_err)
  end)

  if not ok then
    error_screen(err)
  end
end)

svc:subscribe('service.stop',
function()
  app:quit()
end)

local timer = os.startTimer(0.25)

while true do
  local evt, arg = os.pullEvent()

  if evt == "timer" and arg == timer then
    deun.add_gui(svc)

    break
  elseif evt == 'key' and arg == keys.space then
    break
  end
end
