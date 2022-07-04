local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local CEnum = require(ReplicatedStorage.CEnum)
local PickupPrompt = require(script.Parent.Parent.PickupPrompt)
local Sink = require(ReplicatedStorage.Sink)

local SMG = {}
SMG.__index = SMG

SMG.BaseModel = ServerStorage.Accessories.Pistol
for _, p in pairs(SMG.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
	end
end
SMG.Name = "SMG"
SMG.Damage = {
	[CEnum.DamageAffinity.Ballistic] = 8,
	[CEnum.DamageAffinity.Energy] = 0,
	[CEnum.DamageAffinity.Chemical] = 0,
	[CEnum.DamageAffinity.Fire] = 0,
	Weight = CEnum.DamageWeight.Light,
}
SMG.Velocity = 100.0
SMG.FireRate = 0.1
SMG.Accuracy = math.rad(15.0)
SMG.MagSize = 60
SMG.ReloadTime = 2.0
SMG.SinkService = Sink:CreateService("SMG", {"Replicate"})

function SMG.new()
	local self = setmetatable({}, SMG)

	self.Model = self.BaseModel:Clone()
	self.Model.Parent = ReplicatedStorage
	self.Consumed = false

	self.Sink = self.SinkService:Relay(
		self.Model,
		self.Damage,
		self.Velocity,
		self.MagSize,
		self.ReloadTime,
		self.FireRate,
		self.Accuracy
	)

	self.Sink["Replicate"]:Connect(function(...) self:Replicate(...) end)

	self.PickupPrompt = PickupPrompt.new(self)

	return self
end

function SMG:Use(plr: Player, target: Vector3)
	-- body
end

return SMG