_parent = 'object'

function Object:init(committer)
  self.contents = ""
  self.committer = committer
  self.closed = false
end

function Object:close()
  self.committer(self.contents)
  self.closed = true
end

function Object:write(str)
  if not self.closed then
    self.contents = self.contents .. str
  end
end

function Object:write_line(str)
  self:write(str .. "\n")
end