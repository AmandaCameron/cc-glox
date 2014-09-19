-- lint-mode: glox-widget

_parent = "veek-widget"

function Widget:init(width, height)
  local width = width or 10
  local height = height or 10

  self.veek_widget:init(1, 1, width, height)

  self.veek_widget.bg = 'black'
  self.veek_widget.fg = 'white'

  local fakeTerm = {}

  -- These only get called once, on the canvas' init.

  function fakeTerm.getSize()
    return self.veek_widget.width, self.veek_widget.height
  end

  function fakeTerm.isColour()
    return term.isColour()
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

  self.canvas:blit(1, 1, c.width, c.height, c:as_redirect())
end

function Widget:resize(w, h)
  self.canvas.width = w
  self.canvas.height = h

  self.term.width = w
  self.term.height = h

  self.veek_widget:resize(w, h)

  self:cast('veek-widget'):trigger("glox.screen.resize")
end
