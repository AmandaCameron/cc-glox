-- Tips program for Glox

if not os.loadAPI("__LIB__/agui/agui") then
  printError("Couldn't load lib-agui")
  return
end

os.loadAPI("__LIB__/glox/glox")

local app = kidven.new('agui-app')

local layout = kidven.new('agui-layout', app.main_window.gooey)

local next_button = kidven.new('agui-button', 1, 1, 'Next', 8)
local prev_button = kidven.new('agui-button', 1, 1, 'Prev', 8)

layout:add(next_button)
layout:add_anchor(next_button, 'left', 'right', -1, -9)
layout:add_anchor(next_button, 'top', 'bottom', -1, -1)

layout:add(prev_button)
layout:add_anchor(prev_button, 'left', 'left', -1, 1)
layout:add_anchor(prev_button, 'top', 'bottom', -1, -1)

layout:reflow()

-- Settings pane, where we set the computer's label

function make_settings()
  local pane = kidven.new('agui-container', 1, 1, 1, 1)
  local layout = kidven.new('agui-layout', pane)

  local label = kidven.new('agui-label', 1, 1, 'Computer Label:')
  local error_lbl = kidven.new('agui-label', 1, 1, '')

  local input = kidven.new('agui-input', 1, 1, 10)

  if os.getComputerLabel() then
    input.value = os.getComputerLabel()
  end

  layout:add(label)
  layout:add(input)
  layout:add(error_lbl)

  if pocket then
    layout:add_anchor(label, 'top', 'top', -1, 2)
    layout:add_anchor(label, 'left', 'left', -1, 0)
    layout:add_anchor(label, 'right', 'right', -1, 0)

    layout:add_anchor(input, 'top', 'bottom', label, 1)
    layout:add_anchor(input, 'left', 'left', label, 0)
    layout:add_anchor(input, 'right', 'right', label, 0)
  else
    layout:add_anchor(label, 'top', 'top', -1, 2)
    layout:add_anchor(label, 'left', 'left', -1, 0)
    layout:add_anchor(label, 'right', 'middle', -1, 1)

    layout:add_anchor(input, 'top', 'top', -1, 2)
    layout:add_anchor(input, 'left', 'right', label, 2)
    layout:add_anchor(input, 'right', 'right', -1, 0)
  end

  layout:add(error_lbl, 'top', 'top', -1, 1)
  layout:add(error_lbl, 'left', 'left', -1, 0)
  layout:add(error_lbl, 'right', 'right', -1, 0)

  local w, h = term.getSize()
  pane:resize(w - 2, h - 5)

  layout:reflow()

  local function verify()
    if input.value ~= "" then
      os.setComputerLabel(input.value)
      return true
    end

    error_lbl.text = "You must set a computer label."

    return false
  end

  return pane, verify
end


local tutorial = {
  { title = "Welcome to Glox!",
    body = [[This program is here to help you get started with the Glox Graphical Shell.

To start, do you see the % in the top-left corner? Clicking that (Keyboard: Alt/Option) opens the Launch Menu. 
You can use the Launch Menu to launch your apps, and also shutdown / restart your ComputerCraft device.

Press the next button for more.]]},
  { title = "The Drawer",
    body = [[Now, you're probably wondering where your minimised apps disappear to. They are placed in a special part of the UI called "The Drawer".

The Drawer also contains an expanded version of some of your MenuBar items, such as the HighBeam Indexing indicator.

In order to open the drawer, you can drag the menubar down on a colour device, or use The Drawer's keyboard shortcut, ctrl-ctrl-d.
Try it now!]] },
  { title = "Customisability",
    body = [[With the Glox Settings app (glox-settings) You can edit the programs that appear in the Launch Menu.

You can also change what MenuBar plugins are currently active using this tool.]] },
  { title = "Highbeam Search",
    body = [[Next, do you see the ? in the top-right? Clicking (Keyboard: ctrl-ctrl-space) that allows you to search your ComputerCraft Device.

If there's a spinning line next to it, that means it's currently indexing your device, and you should wait until that's finished.]] },
  { title = "Computer Settings",
    content = make_settings },
  { title = "That's it!", 
    body = [[If at any time you wish to re-run this programs, just click "Run..." in the Launch Menu and type "glox-onboarding"

Have fun with Glox, and please remember to report any bugs you find!

Click "Done" to exit this app.]] },
}

local pos = 1
local pane = nil
local verify = nil

function update_gooey()
  app.main_window:set_title(tutorial[pos].title)

  if pane then
    layout:remove(pane)
    pane = nil
  end

  if tutorial[pos].content then
    pane, verify = tutorial[pos].content()

    app:select(pane)
  else
    verify = nil
    pane = kidven.new('agui-textbox', 1, 1, 1, 1)

    pane.agui_widget.fg = 'black'
    pane.agui_widget.bg = 'lightGrey'

    pane:set_text(tutorial[pos].body)
  end
  
  layout:add(pane)

  layout:add_anchor(pane, 'left', 'left', -1, 1)
  layout:add_anchor(pane, 'top', 'top', -1, 1)
  layout:add_anchor(pane, 'right', 'right', -1, 1)
  layout:add_anchor(pane, 'bottom', 'bottom', -1, -2)

  layout:reflow()

  prev_button:set_enabled(pos ~= 1)

  if pos == #tutorial then
    next_button.text = "Done"
  else
    next_button.text = "Next"
  end
end

app:subscribe('gui.button.pressed', function(_, id)
  if id == next_button.agui_widget.id then
    if not verify or verify() then
      if pos < #tutorial then
        pos = pos + 1
        update_gooey()
      else
        app:quit()
      end
    end
  elseif id == prev_button.agui_widget.id then
    if pos > 1 then
      pos = pos - 1
      update_gooey()
    end
  end
end)

update_gooey()

app:subscribe('gui.resized', function()
  layout:reflow()
end)

app.main_window:add_flag('glox.fullscreen')

app:main()

app.main_window:remove_flag('glox.fullscreen')

local settings = kidven.new('glox-settings')

settings:set_onboarded(true)