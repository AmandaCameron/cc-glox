os.loadAPI("__LIB__/agui-shell/gloxhell")

local t = term.native

if type(t) == 'function' then
  t = t()
end

if not t.isColour() then
  printError("Must be run on advanced computer ( for now. )")
  return
end

if multishell and multishell.getCount() > 1 then
  printError("Must not be run with multiple multishell tabs open.")
  return
end

local app = kidven.new('glox-app', t)

app.shell = shell
app.pocket = pocket

app:main()
