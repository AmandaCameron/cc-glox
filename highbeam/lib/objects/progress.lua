-- lint-mode: glox-highbeams

_parent = "object"

function Object:init(db, operation, parent)
  self.db = db
  self.name = operation

  self.total = 1
  self.progress = 0

  self.parent = parent

  self.db:notify("task.begin", self.name)
end

function Object:sub(name)
  return new('hb-progress', self.db, name, self)
end

function Object:done()
  self.db:notify("task.done", self.name)
end

function Object:add_total(num)
  self.total = self.total + num

  self:notify()

  if self.parent then
    self.parent:add_total(num)
  end
end

function Object:add_progress(num)
  self.progress = self.progress + num

  self:notify()

  if self.parent then
    self.parent:add_progress(num)
  end
end

function Object:notify()
  self.db:notify("task.progress", self.name, self.progress, self.total)
end
