-- lint-mode: glox-highbeam

-- Program Indexer

local blist = {
  'startup',
}

_parent = "hb-importer"

function Importer:init(db)
  self.hb_importer:init(db)
end

function Importer:import(scan_task, env)

  local task = scan_task:sub("Programs")
  local shell = env.shell

  if not shell then
    return
  end

  local trans = self:transaction()

  local type = trans:add_object('hb-type://program')
  trans:add_metadata(type, 'name', 'Programs')
  trans:add_metadata(type, 'order', 100)

  local programs = shell.programs()

  task:add_total(#programs)

  for _, program in ipairs(programs) do
    -- Make sure it's a valid and non-blacklisted program first.

    local file = shell.resolveProgram(program)

    if not blist[program] and loadfile(file) ~= nil then
      local pid = trans:add_object('cos-program://' .. program)

      trans:add_metadata(pid, "type", "program")
      trans:add_metadata(pid, "name", program)
      trans:add_metadata(pid, "location", 'file://localhost/' .. file)

      -- Extract pretty-ness from the comments on the top of
      -- the file.
      local f = io.open(file, "r")

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
            if not argument:match("%dx%d") then
              argument = argument .. "x" .. argument
            end

            trans:add_metadata(pid, "icon-" .. argument, value)
          else
            trans:plugins("program_meta", pid, name, argument, value)
          end
        else
          break
        end
      end

      f:close()
    end

    task:add_progress(1)
  end

  task:done()

  trans:commit()
end
