-- Floppy drive "mount" type.
-- Only successfully mounts if there's a disk in the drive.

-- lint-mode: huaxn-fs

os.loadAPI("__LIB__/huaxn/filesystems/bind")

function new(side)
  local path = disk.getMountPath(side)

  if not path then
    error("Invalid Side: No disk.", 2)
  end

  local vfs = bind.new(path)

  function vfs.drive_label()
    return disk.getLabel(side)
  end

  return vfs
end
