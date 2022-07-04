local TweenService = game:GetService("TweenService")

local Barrier = {}
Barrier.__index = Barrier

function Barrier.new(sink: any, model: Model)
	local self = setmetatable({}, Barrier)
	self.Model = model
	self.Sink = sink
	return self
end

function Barrier:TakeDamage(amount: number, dealer: Player?)
	self.Sink["Hit"]:FireServer(amount, dealer)
end

return Barrier