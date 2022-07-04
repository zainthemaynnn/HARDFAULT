local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)
local Tw33n = require(ReplicatedStorage.Util.Tw33n)

local Apostle = {}
Apostle.__index = Apostle

function Apostle.new(sink: any, model: Model)
	local self = setmetatable({}, Apostle)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.CastBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.RedOrb, 100))
	self.Caster = Projectiles.caster()
	self.Caster.RayHit:Connect(function(cast: any, result: RaycastResult)
		if cast.Subject then
			cast.Subject:TakeDamage({
				Type = "Projectile",
				Cast = cast,
				Hit = result,
				Amount = 10,
			})
		end
	end)

	return self
end

function Apostle:Spawn(...)
	SpawnIndicator.smoke(...)
end

function Apostle:TakeDamage(dmg: any)
	self.Sink:Get("TakeDamage"):FireServer(dmg)
end

function Apostle:Cross(speed: number, count: number, a0: number, duration: number)
	self.Animator:Play("DualCast")
	for _=1, count do
		for _, dir in pairs(Projectiles.VecTools.circle(4)) do
			local pos0 = self.Model.PrimaryPart.Position
			dir = Projectiles.VecTools.rotate(dir, a0)
			self.Caster:Fire(pos0, dir, speed, self.CastBehavior)
		end
		SFX:Play("CrystalShot")
		task.wait(_G.time(duration/count))
	end
end

function Apostle:Stream(initialV: number, finalV: number, fireRate: number, duration: number, delay: number)
	self.Animator:Play("RCast")

	local target = Players.LocalPlayer

	local k = duration/fireRate
	for t=1,k do
		local pos0 = self.Model.PrimaryPart.Position
		local dir = (target.Character.PrimaryPart.Position - pos0).Unit * Vector3.new(1, 0, 1)
		local speed = initialV + (finalV - initialV) * (t/k)
		self.Caster:Fire(pos0, dir, speed, self.CastBehavior)
		SFX:Play("CrystalShot")
		task.wait(_G.time(fireRate))
	end
end

function Apostle:Teleport(position: Vector3, delay: number)
	local marker = (function()
		local pt = Instance.new("Part")
		pt.Size = Vector3.new()
		pt.Color = BrickColor.new("Crimson").Color
		pt.Material = Enum.Material.Neon
		pt.Anchored = true
		pt.CanCollide = false
		return pt
	end)()
	marker.Position = position + Vector3.yAxis * 3.0
	marker.Parent = workspace
	self.Animator:Play("Charge")
	for _, dir in pairs(Projectiles.VecTools.circle(8)) do
		local pos0 = self.Model.PrimaryPart.Position
		self.Caster:Fire(pos0, dir, 16.0, self.CastBehavior)
	end
	SFX:Play("CrystalShot")
	game:GetService("TweenService"):Create(marker, TweenInfo.new(_G.time(delay)), { Size = Vector3.new(2, 2, 2) }):Play()
	Tw33n.tweenDescendantsOfClass(self.Model, "BasePart", TweenInfo.new(_G.time(delay)), { Transparency = 1 })
	task.wait(_G.time(delay))
	SFX:Play("WhooshTP")
	Tw33n.cubeSplit(marker, TweenInfo.new())
	Tw33n.tweenDescendantsOfClass(self.Model, "BasePart", TweenInfo.new(0.5), { Transparency = 0 })
	self.Animator:Stop("Charge")

	task.wait(_G.time(0.1))
	for _, dir in pairs(Projectiles.VecTools.circle(8)) do
		local pos0 = self.Model.PrimaryPart.Position
		self.Caster:Fire(pos0, dir, 16.0, self.CastBehavior)
	end
	SFX:Play("CrystalShot")
end

function Apostle:Die()
	-- body
end

return Apostle