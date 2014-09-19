-- Starts veek-shell!

os.loadAPI("__LIB__/huaxn/huaxn")
os.loadAPI('__LIB__/glox/glox')
os.loadAPI("__LIB__/deun/deun")

local svc = kidven.new('deun-service', 'glox', 'Graphical Environment powered by Project Veek')

local t = term.native
  
if type(t) == "function" then
  t = t()
end


local app = kidven.new('glox-app', t)
app.shell = shell

svc:subscribe('service.start',
function()
  app:draw()
  app:main()
end)

svc:subscribe('service.stop', 
function()
  app:quit()
end)

deun.add_gui(svc)
