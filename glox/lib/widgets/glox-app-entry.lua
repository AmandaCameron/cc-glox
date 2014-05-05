-- Shows an entry in the app picker display.

_parent = 'agui-list-item'

function Widget:init(name, cmd)
  self.agui_list_item:init()

  self.agui_widget.height = 3

  self.name = name
  self.command = cmd
end

function Widget:draw(c)
  c:set_fg("black")
  c:set_bg("white")

  c:clear()


  -- TODO: An Icon would be nice.
  
  c:set_fg("red")
  c:set_bg("red")

  c:move(1, 1)
  c:write("   ")
  c:move(1, 2)
  c:write("   ")
  c:move(1, 3)
  c:write("   ")

  c:set_fg("black")
  c:set_bg("white")

  c:move(4, 1)
  c:write(self.name)
end
