-- lint-mode: glox-widget

_parent = 'agui-list-item'

function Widget:init(name, cmd, icon)
  self.agui_list_item:init()

  self.agui_widget.height = 5

  self.name = name
  self.command = cmd
  self.icon = icon
end

function Widget:draw(c)
  local icon = c:sub(2, 2, 3, 4)

  if self.icon then
    self.icon:render(icon, 'red')
  end

  c:set_fg('black')
  c:move(7, 2)
  c:write(self.name)

  c:set_fg('lightGrey')
  c:move(7, 4)
  c:write(self.command)
end
