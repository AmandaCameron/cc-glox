-- Updates agui-shell.
-- TODO: Make this full-screen.

os.loadAPI("__LIB__/acg/acg")

local state = acg.load_state()

local function check_package(pkg)
	for _, dep in ipairs(pkg.dependencies) do
		check_package(state:get_packge(dep))
	end

	if pkg.version > pkg.i_version then
		state:install(pkg)
	end
end

local x, y = term.getCursorPos()
local w, h = term.getSize()

local prev_task = nil

state:hook("task_begin", function(id)
  x, y = term.getCursorPos()
end)

state:hook("task_update", function(id, detail, cur, max)
  local txt = cur .. "/" .. max

  if max == 0 then
    txt = cur .. ""
  end

  term.setCursorPos(x, y)
  term.clearLine()


  if #detail > w - #txt - 1 then
    detail = detail:sub(1, w - #txt - 4) .. "..."
  end


  term.write(detail)

  term.setCursorPos(w - #txt + 1, y)
  term.write(txt)
end)

state:hook("task_complete", function(id, detail)
  local txt = "Complete"

  if detail ~= "" then
    term.setCursorPos(x, y)
    term.clearLine()


    if #detail > w - #txt - 1 then
      detail = detail:sub(1, w - #txt - 4) .. "..."
    end

    term.write(detail)
  end

  term.setCursorPos(w - #txt + 1, y)
  term.write(txt)

  print()
end)

--[[
state:hook("task_error", function(id, detail)
  local txt = "Error"

  if detail ~= "" then
    term.setCursorPos(x, y)
    term.clearLine()

    if #detail > w - #txt - 1 then
      detail = detail:sub(1, w - #txt - 4) .. "..."
    end

    term.write(detail)
  end

  term.setCursorPos(w - #txt + 1, y)

  if term.isColour() then
    term.setTextColour(colours.red)
  end

  term.write(txt)

  if term.isColour() then
    term.setTextColour(colours.white)
  end
  
  print()
end)


for _, repo in pairs(state.repos) do
	repo:update()
end

check_package(state:get_package("agui-shell"))
--]]
