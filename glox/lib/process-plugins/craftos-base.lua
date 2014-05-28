-- MultiShell API shim for glox-process

_parent = "glox-process-plugin"


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

-- Plugin Thing

function Plugin:init(app, proc)
  self.glox_process_plugin:init(app, proc)
end

function Plugin:env(env)
  -- Pull in the OS API.

  env.os = {}

  for name, value in pairs(os) do
    env.os[name] = value
  end

  local loading = {}

  -- Re-implement os.loadAPI

  function env.os.loadAPI(path)
    if loading[path] then
      error("API " .. huaxn.getName(path) .. " is already loading.", 2)
    end

    loading[path] = true

    local func = env.loadfile(path)

    local api = {}

    setmetatable(api, { __index = env })

    setfenv(func, api)

    local ok, err = pcall(function() func() end)

    if not ok then
      printError(err)
      return false
    end

    env[huaxn.getName(path)] = api

    loading[path] = nil

    return true
  end

  -- Bring in the default lua-side APIs.

  for _, api in ipairs(huaxn.list('rom/apis')) do
    if not huaxn.isDir(huaxn.combine('rom/apis', api)) then
      env.os.loadAPI(huaxn.combine('rom/apis', api))
    end
  end

  if pocket then
    env.pocket = pocket

    for _, api in ipairs(huaxn.list('rom/apis/pocket')) do
      if not huaxn.isDir(huaxn.combine('rom/apis/pocket', api)) then
        env.os.loadAPI(huaxn.combine('rom/apis/pocket', api))
      end
    end
  elseif turtle then
    env.turtle = turtle

    for _, api in ipairs(huaxn.list('rom/apis/turtle')) do
      if not huaxn.isDir(huaxn.combine('rom/apis/turtle', api)) then
        env.os.loadAPI(huaxn.combine('rom/apis/turtle', api))
      end
    end
  end


  -- Replicate the multishell API.

  local multishell = {}

  function multishell.launch(env, ...)
    self:app():launch(table.concat({...}, " "))
  end

  function multishell.setTitle(proc, title)
    self:proc().windows[1].agui_window.title = title
  end

  function multishell.getCurrent()
    return 1
  end

  function multishell.getTitle()
    return self:proc().windows[1].agui_window.title
  end

  function multishell.getCount()
    return 1
  end

  env.multishell = multishell

  -- Shell API.

  local shell = {}

  for name, func in pairs(self:app().shell) do
    shell[name] = func
  end

  local stack = {cmd}

  function shell.setDir(dir)
    self:proc().cwd = dir
  end

  function shell.dir()
    return self:proc().cwd
  end


  function shell.switch()
    -- Do Nothing.
  end

  function shell.launch(cmdLine)
    self:app():launch(cmdLine)
  end

  local cmd_stack = {}
  local title_stack = {}


  function shell.run(cmdLine)
    local args = tokenise(cmdLine)

    local cmd = table.remove(args, 1)

    table.insert(cmd_stack, cmd)

    local prog = shell.resolveProgram(cmd)
    local result = false

    local res = self:app().highbeam:get('cos-program://' .. fs.getName(prog))

    if res and res.meta['name'] then
      table.insert(title_stack, res.meta['name'])

      multishell.setTitle(1, res.meta['name'])
    else
      table.insert(title_stack, cmd)

      multishell.setTitle(1, cmd)
    end

    if res and res.meta['icon-4x3'] then
      self:proc().icon = res.meta['icon-4x3']
    else
      self:proc().icon = '__LIB__/glox/res/icons/program'
    end

    if prog then
      local func = env.loadfile(prog)

      if func then
        local old_term

        if term.current then
          old_term = term.current()
        end

        local ok, err = pcall(function()
          func(unpack(args))
        end)

        if old_term then
          term.redirect(old_term)
        end

        result = ok

        if not ok then
          printError(err)
        end
      else
        result = false
      end
    else
      printError("No such program.")
    end

    if #cmd_stack > 1 then
      table.remove(title_stack, #title_stack)
      table.remove(cmd_stack, #cmd_stack)

      multishell.setTitle(1, title_stack[#title_stack])
    else
      multishell.setTitle(1, "Process Done.")
    end

    return result
  end



  function shell.getRunningProgram()
    return stack[#stack]
  end

  function shell.exit()
    -- TODO.
  end

  env.shell = shell

  env.print = print
  env.write = write
  env.read = read

  env.printError = printError
end
