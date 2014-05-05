-- Web FileSystem for Huaxn.
-- Allows reading from HTTP Hosts like local files.

function new(base)
  local vfs = {}

  function vfs.is_read_only()
    return true
  end

  function vfs.open(path, mode)
    if mode ~= "r" then
      error("Mode Not Supported", 3)
    end

    return http.get(base .. "/" .. path)
  end

  function vfs.exists(path)
    local f = http.get(base .. "/" .. path, "r")
    
    if f ~= nil then
      f.close()
      return true
    end

    return false
  end

  function vfs.drive_name(path)
    return "web " .. base
  end

  function vfs.is_dir(path)
    error("Invalid Operation", 3)
  end

  function vfs.list(path)
    return {}
  end

  return vfs
end
