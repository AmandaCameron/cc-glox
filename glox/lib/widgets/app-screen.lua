_parent = "agui-widget"

function Widget:init(colour, width, height)
  local width = width or 10
  local height = height or 10
  local colour = colour or term.isColour()

  self.agui_widget:init(1, 1, width, height)

  self.agui_widget.bg = 'black'
  self.agui_widget.fg = 'white'

  local fakeTerm = {}

  -- These only get called once, on the canvas' init.

  function fakeTerm.getSize()
    return self.agui_widget.width, self.agui_widget.height
  end

  function fakeTerm.isColour()
    return colour
  end

  self.canvas = canvas.new(fakeTerm, nil, width, height, true)

  self.term = self.canvas:as_redirect()
end

function Widget:draw(c, theme)
  c:set_fg(self.canvas.fg)
  c:set_bg(self.canvas.bg)
  c:clear()

  self.canvas.width = c.width
  self.canvas.height = c.height

  self.canvas.ctx = c:as_redirect()

  self.canvas:blit(1, 1, nil, nil)
end

function Widget:resize(w, h)
  self.canvas.width = w
  self.canvas.height = h

  self.term.width = w
  self.term.height = h

  self.agui_widget:resize(w, h)

  self:cast('agui-widget'):trigger("glox.screen.resize")
end
