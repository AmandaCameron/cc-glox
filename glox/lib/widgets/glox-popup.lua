-- lint-mode: glox-widget

_parent = 'veek-container'

function Widget:init(app, width, height)
  self.veek_container:init(1, 1, 1, 1)
  self:resize(width, height)

  self.veek_widget.bg = 'transparent'
  self.veek_widget.fg = 'transparent'

  self.app = app

  self.point_at = 0
  self.point_side = 0
end

function Widget:point_left(y)
  self.point_at = y
  self.point_side = 0

  self:reflow()
end

function Widget:point_up(x)
  self.point_at = x
  self.point_side = 1

  self:reflow()
end

function Widget:point_right(d)
  self.point_at = y
  self.point_side = 2

  self:reflow()
end

function Widget:point_down(x)
  self.point_at = x
  self.point_side = 3

  self:reflow()
end

function Widget:show()
  self.app:add(self)
  self.app:select(self)
end

function Widget:hide()
  self.app:remove(self)
end

function Widget:resize(w, h)
  self.base_width = w
  self.base_height = h

  self:reflow()
end

function Widget:reflow()
  if self.point_side == 1 or self.point_side == 3 then
    self.veek_widget:resize(self.base_width + 2, self.base_height + 3)
  elseif self.pointer_side == 0 or self.pointer_side == 2 then
    self.veek_widget:resize(self.base_width + 3, self.base_height + 2)
  end
end

-- Events.

function Widget:clicked(x, y, btn)
  if self.point_side == 1 then
    self.veek_container:clicked(x - 2, y - 3, btn)
  elseif self.point_side == 0 then
    self.veek_container:clicked(x - 3, y - 2, btn)
  else
    self.veek_container:clicked(x - 2, y - 2, btn)
  end
end

function Widget:draw(pc)
  pc:set_bg('white')
  pc:set_fg('black')

  local c

  if self.point_side == 0 then
    pc:move(1, self.point_at)
    pc:write("<")

    c = pc:sub(2, 1, pc.width - 1, pc.height - 1)
  elseif self.point_side == 1 then
    pc:move(self.point_at, 1)
    pc:write("^")

    c = pc:sub(1, 2, pc.width, pc.height - 1)
  elseif self.point_side == 2 then
    pc:move(pc.width, self.point_at)
    pc:write(">")

    c = pc:sub(1, 1, pc.width - 1, pc.height - 1)
  elseif self.point_side == 3 then
    pc:move(self.point_at, pc.height)
    pc:write("v")

    c = pc:sub(1, 1, pc.width - 1, pc.height - 1)
  end

  c:set_bg('white')
  c:clear()

  c = c:sub(2, 2, c.width - 2, c.height - 2)

  c:set_fg('black')
  c:set_bg('white')
  c:clear()


  self.veek_container:draw_children(c)
end

function Widget:blur()
  self:hide()
end
