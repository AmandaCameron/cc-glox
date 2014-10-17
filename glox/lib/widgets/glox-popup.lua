-- lint-mode: glox-widget

_parent = 'veek-container'

function Widget:init(app, width, height)
  self.veek_container:init(1, 1, width + 4, height + 4)

  self.veek_widget.bg = 'transparent'
  self.veek_widget.fg = 'transparent'

  self.app = app

  self.point_at = 0
  self.point_side = 0
end

function Widget:point_left(y)
  self.point_at = y
  self.point_side = 0
end

function Widget:point_up(x)
  self.point_at = x
  self.point_side = 1
end

function Widget:point_right(d)
  self.point_at = y
  self.point_side = 2
end

function Widget:point_down(x)
  self.point_at = x
  self.point_side = 3
end

function Widget:show()
  self.app:add(self)
  self.app:select(self)
end

function Widget:hide()
  self.app:remove(self)
end

function Widget:resize(w, h)
  self.veek_widget:resize(w + 4, h + 4)
end

-- Events.

function Widget:clicked(x, y, btn)
  self.veek_container:clicked(x - 2, y - 2, btn)
end

function Widget:draw(pc)
  pc:set_bg('white')
  pc:set_fg('black')

  if self.point_side == 1 then
    pc:move(self.point_at, 1)

    pc:write("^")
  end

  local c = pc:sub(2, 2, pc.width - 2, pc.height - 2)

  c:set_fg('black')
  c:set_bg('white')
  c:clear()

  self.veek_container:draw_children(c:sub(2, 2, c.width - 2, c.height - 2))
end

function Widget:blur()
  self:hide()
end
