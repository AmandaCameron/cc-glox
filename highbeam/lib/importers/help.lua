-- lint-mode: glox-highbeam

-- Help Indexer

_parent = "hb-importer"

function Importer:init(db)
  self.hb_importer:init(db)
end

function Importer:import(env)
  local trans = self:transaction()

  local t = trans:add_object("hb-type://help-page")
  trans:add_metadata(t, 'name', 'Help Pages')

  for _, topic in ipairs(help.topics()) do
    local tid = trans:add_object("help://" .. topic)

    trans:add_metadata(tid, "type", "help-page")

    trans:add_metadata(tid, "name", topic)

    self:scan(trans, tid, topic)
    self:scan_file(trans, tid, help.lookup(topic))
    sleep(0.05)
  end

  trans:commit()
end
