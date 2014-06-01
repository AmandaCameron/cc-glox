-- Native FS, uses the native FS functions to mount a
-- directory.

-- lint-mode: huaxn-fs

function new(root)
  local vfs = {
    open_files = {}
  }

  function vfs.open(path, mode)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return nil
    end

    return huaxn.native.open(fs.combine(root, path), mode)
  end

  function vfs.list(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return {}
    end

    return huaxn.native.list(fs.combine(root, path))
  end

  function vfs.delete(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return
    end


    huaxn.native.delete(fs.combine(root, path))
  end

  function vfs.is_dir(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return false
    end

    return huaxn.native.isDir(fs.combine(root, path))
  end

  function vfs.is_read_only(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return false
    end
  end

  function vfs.exists(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return false
    end

    return huaxn.native.exists(fs.combine(root, path))
  end

  function vfs.free(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return tonumber("inf")
    end

    return huaxn.native.getFreeSpace(fs.combine(root, path))
  end

  function vfs.size(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return 0
    end

    return huaxn.native.getSize(fs.combine(root, path))
  end

  function vfs.make_dir(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return 0
    end

    huaxn.native.makeDir(fs.combine(root, path))
  end

  function vfs.drive_name(path)
    if fs.combine(root, path):sub(1, #root) ~= root then
      return nil
    end

    return huaxn.native.getDrive(fs.combine(root, path))
  end

  function vfs.drive_label()
    if vfs.drive_name('') ~= "hdd" then
      return vfs.drive_name('')
    end

    if os.getComputerLabel() then
      return os.getComputerLabel() .. " HD"
    end

    if turtle then
      return "Turtle HD"
    elseif pocket then
      return "Pocket Computer HD"
    end

    return "Computer HD"
  end

  return vfs
end
