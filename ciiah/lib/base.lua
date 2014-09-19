-- Base Library for Ciiah, the program launch database.

-- lint-mode: api

os.loadAPI("__LIB__/kidven/kidven")
os.loadAPI("__LIB__/highbeam/highbeam")

local Object = {}

function Object:init()
  self.hb = kidven.new("hb-connection")
end

function Object:make_cmd(format,uri, mime,  protocol, host, path )
  local command = format:gsub("%%P", protocol)
  command = command:gsub("%%h", host)
  command = command:gsub("%%p", path)
  command = command:gsub("%%u", uri)

  command = command:gsub("%%m", mime)
end

function Object:resolve(uri, mime)
  local protocol = uri:match("^([^:]+)://")
  local host = uri:sub(#protocol + 4):match("^([^/]+)")
  local path = uri:sub(#protocol + #host + 5)

  local programs = {}

  for _, result in ipairs(self.hb:query("type:program")) do
    local program = {
      protocols = {},
      mimes = {},
      name = result.meta["name"],
      format = "",
      icon = result.meta["icon-4x3"],
    }

    if result.meta["uri-open-" .. protocol] then
      program.format = result.meta["location"]:sub(17) .. " " .. result.meta["uri-open-" .. protocol]
    elseif result.meta["mime-" .. mime] then
      program.format = result.meta["location"]:sub(17) .. " " .. result.meta["mime-" .. mime]
    end

    program.command = self:make_cmd(program.format, uri, mime, protocol, host, path)

    if program.protocols[protocol] or program.mimes[mime] then
      table.insert(programs, program)
    end

    if program.format ~= "" then
      programs[#programs + 1] = program
    end
  end

  for _, program in ipairs(self:old_resolve(uri, mime, protocol, host, path)) do
    programs[#programs + 1] = program
  end

  return programs
end

function Object:old_resolve(uri, mime, protocol, host, path)
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

    program.command = self:make_cmd(program.format, uri, mime, protocol, host, path)

    if program.protocols[protocol] or program.mimes[mime] then
      table.insert(programs, program)
    end
  end

  return programs
end

kidven.register('ciiah-database', Object, 'object')
