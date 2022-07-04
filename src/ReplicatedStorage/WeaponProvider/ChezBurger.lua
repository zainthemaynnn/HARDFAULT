local ChezBurger = {}
ChezBurger.__index = ChezBurger

ChezBurger.Name = "ChezBurger"

function ChezBurger.new(sink: any, model: Model)
	local self = setmetatable({}, ChezBurger)
	self.Sink = sink
	self.Model = model
	return self
end

function ChezBurger:Use(clientPacket: any)
	-- body
end

return ChezBurger