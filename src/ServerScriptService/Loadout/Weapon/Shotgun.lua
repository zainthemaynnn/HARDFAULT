local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CEnum = require(ReplicatedStorage.CEnum)
local PickupPrompt = require(script.Parent.Parent.PickupPrompt)
local Sink = require(ReplicatedStorage.Sink)

local Shotgun = {}
Shotgun.__index = Shotgun

Shotgun.BaseModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Shotgun.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
	end
end
Shotgun.Name = "Shotgun"
Shotgun.Damage = {
	[CEnum.DamageAffinity.Ballistic] = 8,
	[CEnum.DamageAffinity.Energy] = 0,
	[CEnum.DamageAffinity.Chemical] = 0,
	[CEnum.DamageAffinity.Fire] = 0,
	Weight = CEnum.DamageWeight.Medium,
}
Shotgun.Velocity = 100.0
Shotgun.Spread = math.rad(30.0)
Shotgun.MagSize = 6
Shotgun.ReloadTime = 2.0
Shotgun.Count = 5
Shotgun.SinkService = Sink:CreateService("Shotgun", {"Replicate"})

function Shotgun.new()
	local self = setmetatable({}, Shotgun)

	self.Model = self.BaseModel:Clone()
	self.Model.Parent = ReplicatedStorage
	self.Consumed = false

	self.Sink = self.SinkService:Relay(
		self.Model,
		self.Damage,
		self.Velocity,
		self.MagSize,
		self.ReloadTime,
		self.Spread,
		self.Count
	)

	self.Sink["Replicate"]:Connect(function(...) self:Replicate(...) end)

	self.PickupPrompt = PickupPrompt.new(self)

	return self
end

function Shotgun:Use(plr: Player, target: Vector3)
	-- body
end

return Shotgun