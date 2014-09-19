-- lint-mode: glox

_parent = "app-screen"

function Widget:init(app, cmdLine, w, h)
  self.app_screen:init(w, h)

  self.veek_widget.main = app

  self.veek_widget:add_flag('active')

  self.mouse_x = 1
  self.mouse_y = 1

  self.app = app

  if cmdLine then
    self.proc = app:new_process(cmdLine, self.app_screen.term)
  end
end

function Widget:clicked(x, y, btn)
  self.mouse_x = x
  self.mouse_y = y

  self.proc:queue_event("mouse_click", btn, x, y)
end

function Widget:dragged(x_del, y_del, btn)
  self.mouse_x = self.mouse_x + x_del
  self.mouse_y = self.mouse_y + y_del

  self.proc:queue_event("mouse_drag", btn, self.mouse_x, self.mouse_y)
end

function Widget:char(c)
  self.proc:queue_event("char", c)
end

function Widget:key(c)
  self.proc:queue_event("key", c)

  return true
end

function Widget:resize(w, h)
  self.app_screen:resize(w, h)

  self.proc:queue_event("window_resize")
  self.proc:queue_event("term_resize")
end
