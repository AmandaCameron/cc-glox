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
    local pid = trans:add_object('cos-program://' .. program)

    trans:add_metadata(pid, "type", "program")

    -- TODO: Extract pretty stuff.
    trans:add_metadata(pid, "name", program)

    trans:add_metadata(pid, "location", shell.resolveProgram(program))
    trans:add_keyword(pid, shell.resolveProgram(program))
  end

  trans:commit()
end