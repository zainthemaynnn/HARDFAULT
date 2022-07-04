local Chavez = {}
Chavez.__index = Chavez

Chavez.Name = "Chavez"

function Chavez.new(sink: any, model: Model)
	local self = setmetatable({}, Chavez)
	self.Sink = sink
	self.Model = model
	return self
end

function Chavez:Use(clientPacket: any)
	-- body
end

return Chavez