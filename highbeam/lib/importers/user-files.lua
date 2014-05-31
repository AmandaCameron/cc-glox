-- lint-mode: glox-highbeam

-- Imports user-files and identifies them using lib-file-ident

os.loadAPI("__LIB__/huaxn/huaxn")
os.loadAPI("__LIB__/file-ident/file_ident")

local system_paths = {
  [huaxn.combine("__LIB__", "")] = true,
  [huaxn.combine("__CFG__", "")] = true,
  [huaxn.combine("__BIN__", "")] = true,
  ["rom"] = true,
}

for path in help.path():gmatch("([^:]+)") do
  system_paths[path] = true
end

_parent = "hb-importer"

function Importer:init(db)
  self.hb_importer:init(db)
end

function Importer:scan_fs(trans, fof)
  if fof == huaxn.combine("__LIB__/state", "highbeam") then
    -- Skip the database!

    return 0
  end

  local id = trans:add_object("file://localhost/" .. fof)

  if huaxn.getLabel(fof) then
    trans:add_metadata(id, "name", huaxn.getLabel(fof))
  else
    trans:add_metadata(id, "name", huaxn.getName(fof))
  end

  trans:add_metadata(id, "drive", huaxn.getDrive(fof))
  trans:add_metadata(id, "read-only", huaxn.isReadOnly(fof))

  trans:add_metadata(id, "system", false)

  for entry in pairs(system_paths) do
    if fof:sub(1, #entry) == entry then
      trans:add_metadata(id, "system", true)
    end
  end

  if huaxn.getName(fof):sub(1,1) == "." then
    trans:add_metadata(id, "fs.hidden", true)
  end

  local size = huaxn.getSize(fof)

  if huaxn.isDir(fof) then
    size = size + 512

    if fof == "" or huaxn.getDrive(fof) ~= huaxn.getDrive(huaxn.combine(fof, "..")) then
      trans:add_metadata(id, "type", "mount")
      trans:add_metadata(id, "free-space", huaxn.getFreeSpace(fof))
    else
      trans:add_metadata(id, "type", "folder")
    end

    for _, fof2 in ipairs(huaxn.list(fof)) do
      if fof2 == ".icon" then
        size = size + huaxn.getSize(huaxn.combine(fof, fof2))
      else
        size = size + self:scan_fs(trans, huaxn.combine(fof, fof2))
      end
    end
  else
    local data = file_ident.identify(fof)

    trans:add_metadata(id, "type", "file")

    if data.mime then
      trans:add_metadata(id, "mime-type", data.mime)
    end

    if data.type == "image" then
      trans:add_metadata(id, "type", "image")

      if data.dimensions then
        trans:add_metadata(id, "dimensions", data.dimensions.width .. "," .. data.dimensions.height)
      end
    end
  end

  trans:add_metadata(id, "size", size)

  sleep(0.10)

  if fof == "" or huaxn.getDrive(fof) ~= huaxn.getDrive(huaxn.combine(fof, "..")) then
    return 0 -- Mount sub-paths shouldn't take up any extra space in their parent.
  end

  return size
end

function Importer:import(env)
  local trans = self:transaction()

  self:scan_fs(trans, "")

  trans:commit()
end
