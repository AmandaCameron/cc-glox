-- Program Indexer

_parent = "hb-importer"

function Importer:init(db)
  self.hb_importer:init(db)
end

function Importer:import(env)
  local shell = env.shell

  if not shell then
    return
  end

  local trans = self:transaction()

  for _, program in ipairs(shell.programs()) do
    -- Make sure it's a valid program first.

    if loadfile(shell.resolveProgram(program)) ~= nil then
      local pid = trans:add_object('cos-program://' .. program)

      trans:add_metadata(pid, "type", "program")
      trans:add_metadata(pid, "name", program)
      trans:add_metadata(pid, "location", 'file://localhost/' .. shell.resolveProgram(program))

      -- Extract pretty-ness from the comments on the top of
      -- the file.
      local f = io.open(shell.resolveProgram(program), "r")

      for line in f:lines() do
        if line:match("^-- (@[A-Z].+: .+)$") then
          local name, value = line:match("^-- @([A-Z].+): (.+)$")
          local argument

          if name:match("^(.+%[.+%])$") then
            name, argument = name:match("^(.+)%[(.+)%]$")
          end

          if name == "Name" then
            trans:add_metadata(pid, "name", value)

            self:scan(trans, pid, value)
          elseif name == "Description" then
            trans:add_metadata(pid, "description", value)

            self:scan(trans, pid, value)
          elseif name == "Author" then
            trans:add_metadata(pid, "author", value)

            self:scan(trans, pid, value)
          elseif name == "Icon" and argument then
            if not arguement:match("%dx%d") then
              argument = argument .. "x" .. argument
            end

            trans:add_metadata("pid", "icon-" .. argument, value)
          end
        else
          break
        end
      end

      f:close()
    end
  end

  trans:commit()
end
