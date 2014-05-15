_parent = "agui-widget"

function Widget:init(app, w, h)
  self.agui_widget:init(1, 2, w, h)

  self.agui_widget.fg = 'glox-desktop-fg'
  self.agui_widget.bg = 'glox-desktop-bg'

  self.app = app

  app:subscribe('glox.settings.commit', function()
    self.background = new('kvio-bundle', app.settings:get_background())
    self.background:load()


    self.image = nil
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
    elseif self.background:get_prop(filename, "Type") == "Image" then
      if not self.image then
        local f = self.background:open(filename, "r")

        -- TODO: Make a better way to get this out of a bundle.

        local f2 = fs.open(".tmp-background", "w")
        f2.write(f:all())
        f2.close()

        f:close()

        self.image = agsimage.load(".tmp-background")

        fs.delete(".tmp-background")
      end

      if self.image then
        if self.background:get_prop(filename, "Mode") == "Center" then
          local w, h = self.image:size()

          self.image:render(c:sub((c.width / 2 - w / 2), (c.height / 2 - h / 2), w, h), "glox-desktop-bg")
        else -- Tile.
          local w, h = self.image:size()

          for y = 1,c.height,h do
            for x = 1,c.width,w do
              self.image:render(c:sub(x, y, w, h), "glox-desktop-bg")
            end
          end
        end
      end
    end
  end
end
