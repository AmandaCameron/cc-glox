-- lint-mode: glox-highbeam

-- Help Indexer

_parent = "hb-importer"

function Importer:init(db)
  self.hb_importer:init(db)
end

function Importer:import(scan_task, env)
  local trans = self:transaction()

  local t = trans:add_object("hb-type://help-page")
  trans:add_metadata(t, 'name', 'Help Pages')

  local topics = help.topics()

  local task = scan_task:sub("Help Topics")

  task:add_total(#topics)

  for _, topic in ipairs(topics) do
    local tid = trans:add_object("help://" .. topic)

    trans:add_metadata(tid, "type", "help-page")

    trans:add_metadata(tid, "name", topic)

    self:scan(trans, tid, topic)
    self:scan_file(trans, tid, help.lookup(topic))

    task:add_progress(1)
  end

  task:done()

  trans:commit()
end
