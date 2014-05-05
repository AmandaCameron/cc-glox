-- Imports user-filea and identifies them using lib-file-ident

local system_paths = {
  [fs.combine("__LIB__", "")] = true,
  [fs.combine("__CFG__", "")] = true,
  [fs.combine("__BIN__", "")] = true,
  ["rom"] = true,
}

for path in help.path():gmatch("([^:]+)") do
  system_paths[path] = true
end

local fs = fs

if huaxn then
  fs = huaxn
end

_parent = "hb-importer"

os.loadAPI("__LIB__/file-ident/file_ident")

function Importer:init(db)
  self.hb_importer:init(db)
end

function Importer:scan(trans, fof)
  if fof == fs.combine("__LIB__/state", "highbeam") then
    -- Skip the database!

    return 0
  end

  local id = trans:add_object("file://localhost/" .. fof)

  if fof == "" and os.getComputerLabel() ~= nil then
    trans:add_metadata(id, "name", os.getComputerLabel() .. " HD")
  elseif disk.isPresent(fs.getDrive(fof)) and disk.getLabel(fs.getDrive(fof)) then
    trans:add_metadata(id, "name", disk.getLabel(fs.getDrive(fof)))
  else
    trans:add_metadata(id, "name", fs.getName(fof))
  end

  trans:add_metadata(id, "drive", fs.getDrive(fof))
  trans:add_metadata(id, "read-only", fs.isReadOnly(fof))

  trans:add_metadata(id, "system", false)

  for entry in pairs(system_paths) do
    if fof:sub(1, #entry) == entry then
      trans:add_metadata(id, "system", true)
    end
  end

  if fs.getName(fof):sub(1,1) == "." then
    trans:add_metadata(id, "fs.hidden", true)
  end

  local size = fs.getSize(fof)

  if fs.isDir(fof) then
    size = size + 512

    if fof == "" or fs.getDrive(fof) ~= fs.getDrive(fs.combine(fof, "..")) then
      trans:add_metadata(id, "type", "mount")
      trans:add_metadata(id, "free-space", fs.getFreeSpace(fof))
    else
      trans:add_metadata(id, "type", "folder")
    end

    for _, fof2 in ipairs(fs.list(fof)) do
      if fof2 == ".icon" then
        trans:add_metadata(id, "icon", fs.combine(fof, fof2))
        size = size + fs.getSize(fs.combine(fof, fof2))
      else
        size = size + self:scan(trans, fs.combine(fof, fof2))
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

  if fof == "" or fs.getDrive(fof) ~= fs.getDrive(fs.combine(fof, "..")) then
    return 0 -- Mount sub-paths shouldn't take up any extra space in their parent.
  end

  return size
end

function Importer:import(env)
  local trans = self:transaction()

  self:scan(trans, "")

  trans:commit()
end