local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CEnum = require(ReplicatedStorage.CEnum)
local PickupPrompt = require(script.Parent.Parent.PickupPrompt)
local Sink = require(ReplicatedStorage.Sink)

local Sniper = {}
Sniper.__index = Sniper

Sniper.BaseModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Sniper.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
	end
end
Sniper.Name = "Sniper"
Sniper.Damage = {
	[CEnum.DamageAffinity.Ballistic] = 40,
	[CEnum.DamageAffinity.Energy] = 0,
	[CEnum.DamageAffinity.Chemical] = 0,
	[CEnum.DamageAffinity.Fire] = 0,
	Weight = CEnum.DamageWeight.Heavy,
}
Sniper.Velocity = 100.0
Sniper.MagSize = 2
Sniper.ReloadTime = 3.0
Sniper.SinkService = Sink:CreateService("Sniper", {"Replicate"})

function Sniper.new()
	local self = setmetatable({}, Sniper)

	self.Model = self.BaseModel:Clone()
	self.Model.Parent = ReplicatedStorage
	self.Consumed = false

	self.Sink = self.SinkService:Relay(
		self.Model,
		self.Damage,
		self.Velocity,
		self.MagSize,
		self.ReloadTime
	)

	self.Sink["Replicate"]:Connect(function(...) self:Replicate(...) end)

	self.PickupPrompt = PickupPrompt.new(self)

	return self
end

function Sniper:Use(plr: Player, target: Vector3)
	-- body
end

return Sniper