-- Identifies Images.

local file = ...

local data = {
  mime = "image/x-simple",
  simple = true,
  dimensions = {
    width = 0,
    height = 0,
  }
}

local nitrogen = {
  [".nfp"] = {
    mime = 'image/x-nfp',
    simple = true,
    dimensions = {
      width = 0,
      height = 0,
    }
  },

  [".nft"] = {
    mime = 'image/x-nft',
    dimensions = {
      width = 0,
      height = 0,
    }
  },

  [".nfa"] = {
    mime = "image/x-nfa",
    animated = true,
    dimensions = {
      width = 0,
      height = 0,
    }
  }
}


if nitrogen[file:sub(-4)] then
  data = nitrogen[file:sub(-4)]
end

data.type = "image"

local f = io.open(file, "r")

local lines = 1

for line in f:lines() do
  if data.animated and line == "~" then
    data.frames = data.frames + 1

    if lines > data.dimensions.height then
      data.dimensions.height = lines
    end

    lines = 1
  end

  if data.simple then
    if not line:match("^[abcdef0123456789 ]*$") then
      return false
    end

    if data.dimensions.width < #line then
      data.dimensions.width = #line
    end
  else
    -- TODO: "Text" NPP Images.
  end

  lines = lines + 1
end

if lines > data.dimensions.height then
  data.dimensions.height = lines
end

f:close()

return true, data
