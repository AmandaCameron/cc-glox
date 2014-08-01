-- lint-mode: glox-widget

_parent = "agui-list-item"

function Widget:init(name, title)
  self.agui_list_item:init()

  self.agui_widget.fg = 'glox-highbeam-category--fg'
  self.agui_widget.bg = 'glox-highbeam-category--bg'

  self.type = name
  self.title = title



  self.agui_widget.height = 2
end

function Widget:draw(c)
  c:clear()

  c:move(2, 2)

  c:write(self.title)
end
