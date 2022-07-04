--!strict
local Deque = {}
Deque.__index = Deque

function Deque.new()
	local self = setmetatable({}, Deque)
	self.First = 0
	self.Last = -1
	self.Elements = {}
	return self
end

function Deque:PushLeft(v)
	self.First -= 1
	self.Elements[self.First] = v
end

function Deque:PushRight(v)
	self.Last += 1
	self.Elements[self.Last] = v
end

function Deque:PopLeft()
	if self:IsEmpty() then
		error("deque is empty :(", 2)
	end

	local v = self.Elements[self.First]
	self.Elements[self.First] = nil
	self.First += 1
	return v
end

function Deque:PopRight()
	if self:IsEmpty() then
		error("deque is empty :(", 2)
	end

	local v = self.Elements[self.Last]
	self.Elements[self.Last] = nil
	self.Last -= 1
	return v
end

function Deque:IsEmpty()
	return self.First > self.Last
end

export type Deque = typeof(Deque.new())

return Deque