local BloxyCola = {}
BloxyCola.__index = BloxyCola

BloxyCola.Name = "BloxyCola"

function BloxyCola.new(sink: any, model: Model)
	local self = setmetatable({}, BloxyCola)
	self.Sink = sink
	self.Model = model
	return self
end

function BloxyCola:Use(clientPacket: any)
	-- body
end

return BloxyCola