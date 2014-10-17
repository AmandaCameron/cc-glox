-- lint-mode: glox-object

_parent = 'object'

function Object:init(text, app, menubar)
	self.app = app
	self.menubar = menubar

	self.text = text
	self.location = 1

	self.colour_bg = 'grey'
	self.colour_fg = 'black'
end

function Object:create_popup(w, h)
	local popup = new('glox-popup', self.app, w, h)

	local x = self.menubar:plugin_x(self) - w / 2

	if x > self.menubar.veek_widget.width - w - 3 then
		x = self.menubar.veek_widget.width - w - 3
	end

	popup:point_up(self.menubar:plugin_x(self) - x)

	popup:move(x, 2)


	return popup
end

function Object:is_visible()
  return true
end

-- If we are to appear in the shade
function Object:is_expandable()
  return false
end

-- If we draw ourselves in the shade.
function Object:is_graphical()
  return false
end

function Object:draw(c)
  -- Do Nothing.
end

function Object:details()
  return "Override me."
end

-- Input

function Object:clicked(button)
	-- Called on a click.
end

function Object:scrolled(dir)
	-- Called on a scroll event.
end

function Object:macro(key)
  -- Called when a ctrl-ctrl-<key> event is triggered.
  -- Or when the shade is open.
end
