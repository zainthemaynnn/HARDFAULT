local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Beam = require(ReplicatedStorage.Effects.Beam)
local Clip = require(ReplicatedStorage.Clip)
local EnemyProvider = require(ReplicatedStorage.EnemyProvider)
local FastCast =  require(ReplicatedStorage.Packages.FastCast)
local SFX = require(ReplicatedStorage.Effects.SFX)

local Sniper = {}
Sniper.__index = Sniper

Sniper.Name = "Sniper"

Sniper.BeamInstance = (function()
	local beam = Instance.new("Beam", workspace.Junk)
	beam.Texture = "http://www.roblox.com/asset/?id=109635220"
	beam.Color = ColorSequence.new(BrickColor.new("Really black").Color)
	beam.Width0 = 0.5
	beam.Width1 = 0.5
	return beam
end)()
Sniper.CastParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "PlrProjectile"
	return params
end)()

function Sniper.new(sink: any, model: Model, damage: any, velocity: number, clipSize: number, reload: number)
	local self = setmetatable({}, Sniper)

	self.Owner = nil
	self.Model = model
	self.Damage = damage
	self.Velocity = velocity
	self.Clip = Clip.new(clipSize, reload, {
		Fire = "Sniper 1",
	})

	self.Sink = sink
	self.Sink:Get("Replicate"):Connect(function(...) self:Use(...) end)

	self.Muzzle = self.Model.Muzzle
	self.Beam = Beam.new(self.BeamInstance)

	return self
end

function Sniper:Use(clientPacket: any, inputState)
	if inputState ~= Enum.UserInputState.Begin then return nil end
	local target = clientPacket.MousePos

	if not self.Clip:Poll() then return end

	self.Beam:SetTransparency(0)
	local res = self.Beam:VisualRaycast(self.Muzzle.Position, (target - self.Muzzle.Position).Unit * 999, self.CastParams)
	self.Beam:Fade(1)
	if not res then return end
	local hit = res.Instance:FindFirstAncestorWhichIsA("Model")
	if not hit then return end
	local enemy = EnemyProvider[hit.Name]
	if not enemy then return end
	enemy:TakeDamage(self.Damage, Players.LocalPlayer)

	return target
end

return Sniper