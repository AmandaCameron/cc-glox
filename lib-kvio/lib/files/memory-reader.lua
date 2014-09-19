-- lint-mode: kidven
_parent = "object"

function Object:init(contents)
  self.contents = contents
  self.line_pos = 0
end

function Object:all()
  local ret = ""

  for _, line in ipairs(self.contents) do
    ret = ret .. line .. "\n"
  end

  return ret:sub(1, -1)
end

function Object:read_line()
   self.line_pos = self.line_pos + 1

   if self.line_pos < #self.contents then
      return self.contents[self.line_pos]
   else
      return nil
   end
end

function Object:lines()
  local line = 0

  local function ret()
    line = line + 1

    return self.contents[line]
  end

  return ret
end

function Object:close()
  -- NOOP
end
