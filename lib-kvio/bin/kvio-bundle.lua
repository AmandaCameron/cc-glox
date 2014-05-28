-- @Name: Bundle Utility
-- @Desscription: Allows extraction / creation of KVIO bundle files.
-- @Author: Amanda Cameron
-- @Usage: kvio-bundle extract <bundle-file> <dest>
-- @Usage: kvio-bundle create <bundle-file> <source>
-- @Usage: kvio-bundle list <bundle-file>

os.loadAPI("__LIB__/kvio/kvio")

local args = {...}

local function print_usage()
  print("Usage: " .. shell.getRunningProgram() .. " <cmd> <cmd-args>")
  print()
  print("   extract <bundle> <dir> Extracts bundle to dir")
  print("   create <bundle> <dir>  Creates bundle from dir")
  print("   list <bundle>          List files in bundle")
end

if #args < 2 then
  print_usage()
  return
end

if args[1] == "create" and #args == 3 then
  local bundle = kidven.new('kvio-bundle', args[2])

  for _, fname in ipairs(fs.list(args[3])) do
    local f = fs.open(fs.combine(args[3], fname), "r")

    local b_f = bundle:open(fname, "w")
    b_f:write(f.readAll())
    b_f:close()
    f.close()
  end

  bundle:save()
elseif args[1] == "extract" and #args == 3 then
  local bundle = kidven.new('kvio-bundle', args[2])

  bundle:load()

  fs.makeDir(args[3])

  for fname in bundle:files() do
    print("Extracting: " .. fname)
    local f = fs.open(fs.combine(args[3], fname), "w")
    local file = bundle:open(fname, "r")

    f.write(file:all())
    f.close()
  end
elseif args[1] == "list" and #args == 2 then
  local bundle = kidven.new('kvio-bundle', args[2])

  bundle:load()

  local files = {}

  for fname in bundle:files() do
    table.insert(files, fname)
  end

  textutils.tabulate(files)
else
  print_usage()
end
