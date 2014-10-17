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

svc:subscribe('service.start',
function()
  app:draw()
  app:main()
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
