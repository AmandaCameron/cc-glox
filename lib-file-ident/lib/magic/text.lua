local file = ...

local data = {
  type = "text",
  mime = "text/plain",
}

local f = fs.open(file, "r")

local contents = f.readAll()

f.close()

for char in contents:gmatch("(.)") do
  if string.byte(char) > 128 then
    -- Abort on binary data.
    return false, nil
  end
end

if loadstring(contents) ~= nil then
  data.mime = "application/x-lua"
end

return true, data