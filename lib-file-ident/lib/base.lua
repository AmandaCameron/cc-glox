-- lint-mode: api

os.loadAPI("__LIB__/kvio/kvio")

function identify(file)
  local data = {
    type = "unknown",
    mime = "x-data",
  }

  for _, ident in ipairs(fs.list("__LIB__/file-ident/magic")) do
    local id = loadfile("__LIB__/file-ident/magic/" .. ident)

    local ok, data = id(file)

    if ok then
      return data
    end
  end

  return data
end
