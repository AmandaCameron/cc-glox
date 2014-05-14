-- Huaxn Library Basepoint

os.loadAPI("__LIB__/huaxn/filesystems/bind")

local mounts = {}

function _get_state()
  return mounts
end

native = huaxn and huaxn.native or fs

local function find_best(path)
  local path = native.combine(path, "")

  local best = ""

  for m_path, fs in pairs(mounts) do
    if path:sub(0, #m_path) == m_path then
      if #best < #m_path then
	     best = m_path
      end
    end
  end

  return best, path
end

-- Huaxn Additions

function mount(path, fs)
  mounts[path] = fs

  os.queueEvent("huaxn-mount", path)
end

function unmount(path)
  for m_path, m_fs in pairs(mounts) do
    if m_path:sub(0,#path) == path then
      if m_path ~= path then
        error("Mount Busy", 2)
      end
    end
  end

  os.queueEvent("huaxn-unmount", path)

  mounts[path] = nil
end

-- FS API

function open(path, mode)
  local best, path = find_best(path)


  local obj = mounts[best].open(path:sub(#best + 1), mode)

  if not obj then
    return nil
  end

  os.queueEvent("huaxn-ipc", "file-open", fs.combine(best, path))

  local orig_close = obj.close

  function obj.close()
    orig_close()

    os.queueEvent("huaxn-ipc", "file-close", fs.combine(best, path))
  end

  return obj
end

function list(path)
  local best, path = find_best(path)
  
  local entries = mounts[best].list(path:sub(#best + 1))

  for m_path, _ in pairs(mounts) do
    if m_path:sub(1, #m_path - #fs.getName(m_path) - 1) == path and m_path ~= "" then
      table.insert(entries, m_path:sub(#path + 2))
    end
  end

  return entries
end


function exists(path)
  local best, path = find_best(path)
  
  return mounts[best].exists(path:sub(#best + 1))
end

function delete(path)
  local best, path = find_best(path)
  
  if mounts[best].is_read_only(path:sub(#best + 1)) then
    error("FileSystem is read-only", 2)
  end
  
  if mounts[best].delete then
    mounts[best].delete(path:sub(#best + 1))
  end
end

function isReadOnly(path)
  local best, path = find_best(path)

  return mounts[best].is_read_only(path:sub(#best + 1))
end

function getDrive(path)
  local best, path = find_best(path)
  
  return mounts[best].drive_name(path:sub(#best + 1))
end

function isDir(path)
  local best, path = find_best(path)
  
  return mounts[best].is_dir(path:sub(#best + 1))
end

function getSize(path)
  local best, path = find_best(path)
  
  return mounts[best].size(path:sub(#best + 1))
end

function makeDir(path)
  local best, path = find_best(path)

  mounts[best].make_dir(path:sub(#best + 1))
end

function getFreeSpace(path)
  local best, path = find_best(path)

  return mounts[best].free(path:sub(#best + 1))
end

local function do_copy(old, new)
  if isDir(old) then
    if not isDir(new) then
      makeDir(new)
    end
    
    for _, file in ipairs(list(old)) do
      do_copy(combine(old, file), combine(new, file))
    end
  else
    local o = open(old, "r")
    local n = open(new, "w")

    n.write(o.readAll())
    
    o.close()
    n.close()
  end
end

function copy(old, new)
  if isReadOnly(new) then
    error("Target is Read-Only", 2)
  end

  do_copy(old, new)
end

function move(old, new)
  if isReadOnly(new) then
    error("Target is Read-Only", 2)
  end

  if isReadOnly(old) then
    error("Source is Read-Only", 2)
  end

  do_copy(old, new)
  delete(old)
end

local function recurse_spec(results, path, spec)
  local segment = spec:match('([^/]*)'):gsub('/', '')
  local pattern = '^' .. segment:gsub("[.]", "[.]"):gsub("[+]", "[+]"):gsub("[-]", "[-]"):gsub('[*]', '.+'):gsub('?', '.') .. '$'

  if isDir(path) then
    for _, file in ipairs(list(path)) do
      if file:match(pattern) then
        local f = combine(path, file)


        if spec == segment then
          table.insert(results, f)
        end

        if isDir(f) and #spec > 0 then
          recurse_spec(results, f, spec:sub(#segment + 2))
        end
      end
    end
  end
end

function find(pattern)
  local results = {}
 
  recurse_spec(results, '', pattern)
  
  return results
end

combine = native.combine
getName = native.getName

-- CC1.63
if native.getDir then
  getDir = native.getDir
end

-- Initalise

if huaxn then
  mounts = huaxn._get_state()
else
  mounts[''] = bind.new('')
end