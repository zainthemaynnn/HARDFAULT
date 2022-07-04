local ServerStorage = game:GetService("ServerStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")

local Node = {}
Node.__index = Node
Node.Model = (function()
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = Vector3.new(2, 2, 2)
	p.CanCollide = false
	return p
end)()

function Node.new(player: Player, text: string, position: Vector3)
	local self = setmetatable({}, Node)
	self.Author = player
	self.Text = text
	self.Position = position
	return self
end

function Node.getEntriesFromPlayer(player: Player)
	-- body
end

return Node