-- lint-mode: glox

_parent = "veek-list-item"

local types = {
  -- Bucket of others.
  ["other"] = "Other",
  -- User-usable Types.
  ["help-page"] = "Help Pages",
  ["program"] = "Programs",
  -- Basic Types.
  ["file"] = "Files",
  ["folder"] = "Folders",
  ["mount"] = "Mount",
}

function Widget:init(name)
  self.veek_list_item:init()

  self.veek_widget.fg = 'glox-highbeam-category--fg'
  self.veek_widget.bg = 'glox-highbeam-category--bg'

  self.type = name

  if types[self.type] then
    self.title = types[self.type]
  else
    self.title = self.type
  end



  self.veek_widget.height = 2
end

function Widget:draw(c)
  c:clear()

  c:move(2, 2)

  c:write(self.title)
end