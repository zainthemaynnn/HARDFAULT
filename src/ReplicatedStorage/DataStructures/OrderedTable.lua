local OrderedTable = {}
OrderedTable.__index = OrderedTable

function OrderedTable.new(taaable, parent)
	local self = setmetatable(taaable or {}, OrderedTable)
	self.Parent = parent
	return self
end

function OrderedTable:__newindex(index, value)
	rawset(self, index, type(value) == "table" and self.new(value, self) or value)
end

function OrderedTable:Climb(ancestors)
	local ancestor = self
	for _ = 1, ancestors do
		if ancestor then
			ancestor = ancestor.Parent
		else
			break
		end
	end
	return ancestor
end

return OrderedTable