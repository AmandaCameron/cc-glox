-- lint-mode: glox-object

-- Process plugin API.

function Object:init(app, process)
  self._app = app
  self.process = process
end

-- Helpers.

function Object:proc()
  return self.process
end

function Object:app()
  return self._app
end

-- Hooks.

function Object:env()
  -- Implement this.
end

function Object:started()
  -- Called when the process is starting.
end

function Object:stopped()
  -- Called when the process is stopping.
end

function Object:paused()
  -- Called when the process yields.
end
