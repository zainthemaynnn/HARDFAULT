local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sink = require(ReplicatedStorage.Sink)

local Door = {}
Door.__index = Door

Door.SinkService = Sink:CreateService("Doors", {
	"Lock",
	"Unlock",
})

function Door.new(model: Model)
	local self = setmetatable({}, Door)
	self.Model = model
	self.Sink = self.SinkService:Relay(self.Model)
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then PhysicsService:SetPartCollisionGroup(p, "Door") end
	end
	return self
end

function Door:Lock(plr: Player)
	print("locking")
	self.Sink["Lock"]:FireClient(plr)
end

function Door:Unlock(plr: Player)
	print("unlocking")
	self.Sink["Unlock"]:FireClient(plr)
end

function Door:Destroy()
	self.Model:Destroy()
	self.Sink:Destroy()
end

return Door