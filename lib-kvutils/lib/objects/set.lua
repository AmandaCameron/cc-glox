_parent = 'object'

function Object:init(contents)
	self.contents = {}

	if contents then
		for _, c in ipairs(contents) do
			self:add(c)
		end
	end
end

function Object:add(obj)
	if not self:contains(obj) then
		self.contents[obj] = true
	end
end

function Object:remove(obj)
	self.contents[obj] = nil
end

function Object:contains(obj)
	if self.contents[obj] then
		return true
	end

	return false
end

function Object:iter()
	return pairs(self.contents)
end

function Object:clear()
	self.contents = {}
end