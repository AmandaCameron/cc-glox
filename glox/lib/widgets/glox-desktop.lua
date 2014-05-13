_parent = "agui-widget"

function Widget:init(app, w, h)
  self.agui_widget:init(1, 2, w, h)

  self.agui_widget.fg = 'glox-desktop-fg'
  self.agui_widget.bg = 'glox-desktop-bg'

  self.app = app

  app:subscribe('glox.settings.commit', function()
    self.background = new('kvio-bundle', app.settings:get_background())
    self.background:load()
  end)
end

function Widget:draw(c)
	c:clear()

  if self.background then
    filename = "computer"

    if pocket then
      filename = "pocket"
    elseif turtle then
      filename = "turtle"
    end
    
    if not self.background:exists(filename) then
      filename = "computer"
    end

    if c.is_colour and self.background:exists("adv-" .. filename) then
      filename = "adv-" .. filename
    end

    if self.background:get_prop(filename, "Type") == "ASCII" then
      local f = self.background:open(filename, "r")
      local width = tonumber(self.background:get_prop(filename, "Width"))

      for y=1,#f.contents do
        c:move(c.width / 2 - width / 2, (c.height / 2 - #f.contents / 2) + y)
        c:write(f.contents[y])
      end

      f:close()
    end
  end
end
