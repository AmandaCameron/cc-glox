-- Lights up if there's a program using the modem.
-- Uses Private thread APIs.

_parent = "mb-plugin"

function Plugin:init(app, menubar)
  self.mb_plugin:init("*", app, menubar)
   
  self.mb_plugin.colour_fg = 'glox-menubar-fg'
  self.mb_pluign.colour_bg = 'glox-menubar-bg'

  self.num_active = {
     left = 0,
     right = 0,
     front = 0,
     back = 0,
     top = 0,
     bottom = 0
  }

  self.menu = new('agui-menu', app)

  app:subscribe("event.glox_ipc", function(_, msg, p1, p2) 
    if msg == "modem" then
       if p1 == "open" then
	  self.num_active[p2] = self.num_active[p2] + 1
	  self:update()
	elseif p1 == "close" then
	   self.num_active[p2] = self.num_active[p2] - 1
	   self:update()
	end
    end
  end)
end

function Plugin:clicked(button)
   self.menu:show(self.mb_plugin.location, 2)
end

function Plugin:update()
   local active = false

   self.menu:clear()

   for side, num in pairs(self.num_active) do
      if num > 0 then
	 active = true
      end
      self.menu:add(side .. ": " .. num)
   end

   if active then
      self.mb_plugin.colour_fg = 'white'
      self.mb_plugin.colour_bg = 'red'
   else
      self.mb_plugin.colour_fg = 'glox-menubar-fg'
      self.mb_pluign.colour_bg = 'glox-menubar-bg'
   end
end
