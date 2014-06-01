-- lint-mode: glox-highbeam

-- Indexer base class.

_parent = "object"

function Object:init(db)
	self.db = db
end

function Object:filters()
  return {}
end

function Object:index(id, entry)
  error("Must me implemented.")
end

function Object:load(f)
  error("Must be implemented")
end

function Object:save(f)
  error("Must be implemnted")
end

function Object:lookup(filter, query)
  error("Must be implemented.")
end

function Object:clear_data()
  error("Must be implemented.")
end
