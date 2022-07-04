local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local HitReg = require(ReplicatedStorage.HitReg)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)
local Tw33n = require(ReplicatedStorage.Util.Tw33n)

local Blockosaur = {}
Blockosaur.__index = Blockosaur

Blockosaur.Projectile = Projectiles.RedOrb

function Blockosaur.new(sink: any, model: Model)
	local self = setmetatable({}, Blockosaur)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.CastBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.RedOrb, 100))
	self.Caster = Projectiles.Caster.new()
	self.Caster.RayHit:Connect(function(cast: any, result: RaycastResult)
		if cast.Subject then
			cast.Subject:TakeDamage({
				Type = "Projectile",
				Cast = cast,
				Hit = result,
				Amount = 8,
			})
		end
	end)

	return self
end

function Blockosaur:TakeDamage(dmg: any)
	self.Sink:Get("TakeDamage"):FireServer(dmg)
	self.Caster:Fire(
		self.Model.PrimaryPart.Position,
		Players.LocalPlayer.Character.PrimaryPart.Position - self.Model.PrimaryPart.Position,
		20.0,
		self.CastBehavior
	)
end

function Blockosaur:Spawn(...)
	SpawnIndicator.smoke(...)
end

function Blockosaur:Burst(
	maxSpeed: number,
	sideLen: number,
	delay: number
)
	self.Animator:Play("Attack", _G.time(delay*4))
	task.wait(_G.time(delay))
	for _, dir in pairs(Projectiles.VecTools.polygon(4, sideLen)) do
		dir = self.Model.PrimaryPart.CFrame:VectorToWorldSpace(
			-- diamond -> square
			Projectiles.VecTools.rotate(dir, math.rad(45))
		)
		self.Caster:Fire(
			self.Model.PrimaryPart.Position,
			dir,
			maxSpeed * dir.Magnitude,
			self.CastBehavior
		)
	end
	SFX:Play("Bass")
end

function Blockosaur:Die()
	Tw33n.tweenDescendantsOfClass(self.Model, "BasePart", TweenInfo.new(), { Transparency = 1 })
end

return Blockosaur