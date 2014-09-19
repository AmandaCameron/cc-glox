-- lint-mode: glox-highbeam

_parent = "hb-importer"

function Importer:init(db)
  self.hb_importer:init(db)
end

function Importer:trans_program_meta(trans, pid, name, argument, value)
  if name == "Uri-Open" and argument then
    trans:add_metadata(pid, "uri-open-" .. argument, value)

  elseif name == "Uri-Mount" and argument then
    trans:add_metadata(pid, "uri-mount-" .. argument, value)

  elseif name == "Mime-Open" and argument then
    trans:add_metadata(pid, "mime-" .. argument, value)

  end
end

function Importer:import(env)
  -- Meh.
end
