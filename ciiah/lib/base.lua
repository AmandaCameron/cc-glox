-- Base Library for Ciiah, the program launch database.

-- lint-mode: api

os.loadAPI("__LIB__/kidven/kidven")

local Object = {}

function Object:init()
end

if not fs.isDir("__CFG__/file-handlers/") then
  fs.makeDir("__CFG__/file-handlers/")
end

function Object:resolve(uri, mime)
  local protocol = uri:match("^([^:]+)://")
  local host = uri:sub(#protocol + 4):match("^([^/]+)")
  local path = uri:sub(#protocol + #host + 5)

  local programs = {}

  for _, file in ipairs(fs.list("__CFG__/file-handlers/")) do
    local f = io.open("__CFG__/file-handlers/" .. file)

    local program = {
      protocols = {},
      mimes = {},
      name = file,
      format = "",
      icon = "",
    }

    for line in f:lines() do
      local dir, value = line:match("^([^:]+): (.+)$")

      if dir == "Protocol" then
        program.protocols[value] = true
      elseif dir == "Mime" then
        program.mimes[value] = true
      elseif dir == "Name" then
        program.name = value
      elseif dir == "Format" then
        program.format = value
      elseif dir == "Icon" then
        program.icon = value
      end
    end

    f:close()

    program.command = program.format:gsub("%%s", protocol)
    program.command = program.command:gsub("%%h", host)
    program.command = program.command:gsub("%%p", path)
    program.command = program.command:gsub("%%u", uri)
    program.command = program.command:gsub("%%m", mime)

    if program.protocols[protocol] or program.mimes[mime] then
      table.insert(programs, program)
    end
  end

  return programs
end

kidven.register('ciiah-database', Object, 'object')
