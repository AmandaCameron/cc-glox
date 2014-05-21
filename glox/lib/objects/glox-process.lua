_parent = "object"

-- Shamelessly stolen from the 'shell' program:

local function tokenise( ... )
  local sLine = table.concat( { ... }, " " )
  local tWords = {}
  local bQuoted = false
  for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
    if bQuoted then
      table.insert( tWords, match )
    else
      for m in string.gmatch( match, "[^ \t]+" ) do
	table.insert( tWords, m )
      end
    end
    bQuoted = not bQuoted
  end
  return tWords
end



function Object:init(app, cmdLine, term)
  self.app = app
  self.icon = "__LIB__/glox/res/icons/program"

  self.id = app.pool:new(function()
    local multishell = {}
    local shell = {}

    -- Replicate the multishell API.

    function multishell.launch(env, ...)
      app:launch(table.concat({...}, " "))
    end

    function multishell.setTitle(proc, title)
      self.windows[1].agui_window.title = title
    end

    function multishell.getCurrent()
      return 1
    end

    function multishell.getTitle()
      return self.windows[1].agui_window.title
    end

    function multishell.getCount()
      return 1
    end

    -- Replicate the shell API.

    shell.setPath = app.shell.setPath
    shell.path = app.shell.path
    shell.setAlias = app.shell.setAlias
    shell.clearAlias = app.shell.clearAlias
    shell.aliases = app.shell.aliases
    shell.programs = app.shell.programs
    shell.resolveProgram = app.shell.resolveProgram
    shell.resolve = app.shell.resolve

    local title_stack = {cmd}
    local program_stack = {cmd}

    function shell.switch()
      -- Do Nothing.
    end

    function shell.launch(cmdLine)
      app:launch(cmdLine)
    end

    function shell.run(cmdLine)
      local args = tokenise(cmdLine)

      local cmd = table.remove(args, 1)

      local res = app.highbeam:get("cos-program://" .. fs.getName(cmd))

      if res and res.meta['name'] then
        self.icon = res.meta['icon']

        table.insert(title_stack, res.meta['name'])

        multishell.setTitle(1, res.meta['name'])
      else
        self.icon = "__LIB__/glox/res/icons/program"

        table.insert(title_stack, cmd)
        
        multishell.setTitle(1, cmd)
      end
      
      table.insert(program_stack, cmd)

      local prog = app.shell.resolveProgram(cmd)
      local result = false

      local fs = fs

      if prog then
        result = os.run({
          shell = shell,
	        multishell = multishell,
          fs = huaxn,
        }, prog, unpack(args));
      else
      	printError("No such program.")
      end
	
      if #program_stack > 1 then
        table.remove(title_stack, #title_stack)
      	table.remove(program_stack, #program_stack)

      	multishell.setTitle(1, title_stack[#title_stack])
      else
      	multishell.setTitle(1, "Process Done.")
      end


      return result
    end


    function shell.getRunningProgram()
      return program_stack[#program_stack][1]
    end

    function shell.exit()
      -- TODO.
    end

    local dir = ''

    function shell.setDir(new)
      dir = new
    end

    function shell.dir()
      return dir
    end

    local ok, err = pcall(
    function()
      shell.run(cmdLine)
    end)

    if not ok then
      term.clear()
      term.setCursorPos(1, 1)
      printError(err)
    end
  end, self, { terminal = term, has_queue = true })

  self.cmdLine = cmdLine

  self.windows = {}
end

-- thread-pool hooks.

function Object:started()
  self.running = true
end

function Object:die()
  -- TODO: Error reporting somewhere?
  self.app.event_loop:trigger("glox.process.exit", self.id)
  
  for _, win in ipairs(self.windows) do
    self.app:remove(win)
  end

  self.running = false
end

function Object:yield()
  self.app:draw()
end

-- Event API
function Object:queue_event(evt, ...)
  self.app.pool:queue_event(self.id, evt, ...)
end
