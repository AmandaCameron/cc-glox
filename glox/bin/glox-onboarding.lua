-- Tips program for Glox

if not os.loadAPI("__LIB__/veek/agui") then
  printError("Couldn't load lib-veek")
  return
end

os.loadAPI("__LIB__/glox/glox")

local app = kidven.new('veek-app')

local layout = kidven.new('veek-layout', app.main_window.gooey)

local next_button = kidven.new('veek-button', 1, 1, 'Next', 8)
local prev_button = kidven.new('veek-button', 1, 1, 'Prev', 8)

layout:add(next_button)
layout:add_anchor(next_button, 'left', 'right', -1, -9)
layout:add_anchor(next_button, 'top', 'bottom', -1, -1)

layout:add(prev_button)
layout:add_anchor(prev_button, 'left', 'left', -1, 1)
layout:add_anchor(prev_button, 'top', 'bottom', -1, -1)

layout:reflow()

-- Settings pane, where we set the computer's label

local function make_settings()
  local pane = kidven.new('veek-container', 1, 1, 1, 1)
  local layout = kidven.new('veek-layout', pane)

  local label = kidven.new('veek-label', 1, 1, 'Computer Label:')
  local error_lbl = kidven.new('veek-label', 1, 1, '')

  local input = kidven.new('veek-input', 1, 1, 10)

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

    layout:add_anchor(input, 'top', 'bottom', label, 0)
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

  layout:add_anchor(error_lbl, 'top', 'top', -1, 1)
  layout:add_anchor(error_lbl, 'left', 'left', -1, 0)
  layout:add_anchor(error_lbl, 'right', 'right', -1, 0)

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

  pane.veek_widget.bg = 'window-bg'
  pane.veek_widget.fg = 'window-fg'

  return pane, verify
end


local tutorial = {
  { title = "Welcome to Glox!",
    body = [[This program is here to help you get started with the Glox Graphical Shell.

So, let's get started. Press the "Next" button below. If you are on a normal computer, press tab until the Next button has {}s around it, instead of []s.]] },
  { title = "Launch Menu",
    body = [[Clicking the % (KB: Alt) in the top-left corner opens the Launch Menu.

You can use the Launch Menu to launch your apps, as well as shutdown / restart your ComputerCraft device.]] },
  { title = "The Drawer",
    body = [[The Drawer is a a UI element hidden in the menubar on top. In order to open it, you can drag down with the mouse. (KB: ctrl-ctrl-d)

The Drawer contains your minimised apps, as well as some expanded information on some of the menu bar items.]] },
  { title = "Customisability",
    body = [[With the Glox Settings app (glox-settings) You can edit the programs that appear in the Launch Menu.

You can also change what plugins are currently active using this tool.]] },
  { title = "Highbeam Search",
    body = [[Next, do you see the ? in the top-right? Clicking (KB: ctrl-ctrl-space) that allows you to search your ComputerCraft Device.

A spinning line next to it means that it is currently indexing your device.]] },
  { title = "Just a few questions...",
    body = [[Next, we're going to ask you some questions to help you get your device setup.]] },
  { title = "Computer Settings",
    content = make_settings },
  { title = "That's it!",
    body = [[If at any time you wish to re-run this setup, just select "Run..." in the Launch Menu and type "glox-onboarding"

Have fun with Glox, and please remember to report any bugs you find!

Click "Done" to exit this app.]] },
}

local pos = 1
local pane = nil
local verify = nil

local function update_gooey()
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
    pane = kidven.new('veek-textbox', 1, 1, 1, 1)

    if term.isColour() then
      pane.veek_widget.fg = 'black'
      pane.veek_widget.bg = 'lightGrey'
    end

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
  if id == next_button.veek_widget.id then
    if not verify or verify() then
      if pos < #tutorial then
        pos = pos + 1
        update_gooey()
      else
        app:quit()
      end
    end
  elseif id == prev_button.veek_widget.id then
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
