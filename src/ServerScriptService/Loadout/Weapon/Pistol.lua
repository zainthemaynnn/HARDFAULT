local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CEnum = require(ReplicatedStorage.CEnum)
local PickupPrompt = require(script.Parent.Parent.PickupPrompt)
local Sink = require(ReplicatedStorage.Sink)

local Pistol = {}
Pistol.__index = Pistol

Pistol.BaseModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Pistol.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
	end
end
Pistol.Name = "Pistol"
Pistol.Damage = {
	[CEnum.DamageAffinity.Ballistic] = 12,
	[CEnum.DamageAffinity.Energy] = 0,
	[CEnum.DamageAffinity.Chemical] = 0,
	[CEnum.DamageAffinity.Fire] = 0,
	Weight = CEnum.DamageWeight.Light,
	Knockback = 6.0,
	Stagger = 1.0,
}
Pistol.Velocity = 100.0
Pistol.MagSize = 12
Pistol.ReloadTime = 1.0
Pistol.SinkService = Sink:CreateService("Pistol", {
	"Replicate"
})

function Pistol.new()
	local self = setmetatable({}, Pistol)

	self.Model = self.BaseModel:Clone()
	self.Model.Parent = workspace
	self.Consumed = false

	self.Sink = self.SinkService:Relay(
		self.Model,
		self.Damage,
		self.Velocity,
		self.MagSize,
		self.ReloadTime
	)

	self.Sink["Replicate"]:Connect(function(...)
		self.Sink["Replicate"]:FireAllClientsExcept(...)
	end)

	return self
end

return Pistol