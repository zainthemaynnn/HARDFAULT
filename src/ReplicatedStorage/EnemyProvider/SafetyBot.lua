local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)
local Tw33n = require(ReplicatedStorage.Util.Tw33n)

local SafetyBot = {}
SafetyBot.__index = SafetyBot

SafetyBot.MuzzleFlash = (function()
	local light = Instance.new("PointLight")
	light.Color = BrickColor.new("Electric blue").Color
	light.Enabled = false
	return light
end)()

function SafetyBot.new(sink: any, model: Model)
	local self = setmetatable({}, SafetyBot)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)
	local track = self.Animator:GetTrack("Stagger")
	track.KeyframeReached:Connect(function(kf)
		if kf == "Staggered" then
			track:AdjustSpeed(0)
		end
	end)

	self.WeaponMuzzle = self.Model.Pistol.Muzzle
	self.MuzzleFlash = self.MuzzleFlash:Clone()
	self.MuzzleFlash.Parent = self.WeaponMuzzle

	self.CastBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.BlueOrb, 10))
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

function SafetyBot:TakeDamage(dmg: any)
	SFX:Play("Metal 1")
	self.Sink:Get("TakeDamage"):FireServer(dmg)
	--Tw33n.hitMark(self.Model)
end

function SafetyBot:Stagger(on: boolean)
	if on then
		--self.Animator:Stop("Idle")
		--self.Animator:Play("Stagger")
	else
		--self.Animator:Stop("Stagger")
		--self.Animator:Play("Idle")
	end
end

function SafetyBot:Spawn(...)
	SpawnIndicator.teleport(...)
end

function SafetyBot:Run(enable: boolean)
	if enable then
		self.Animator:PlayIfNotPlaying("Run")
	else
		self.Animator:Stop("Run")
	end
end

-- standard assult rifle attack
function SafetyBot:Burst(
	target: Player,
	speed: number,
	fireRate: number,
	offset: number,
	count: number,
	delay: number
)
	local pos0, pos1 = self.WeaponMuzzle.Position, target.Character.PrimaryPart.Position
	local dir = Projectiles.VecTools.rotate((pos1 - pos0).Unit, offset)

	task.wait(_G.time(delay))

	--for _=1, count do
		self.MuzzleFlash.Enabled = true
		self.Caster:Fire(pos0, dir, speed, self.CastBehavior)
		self.MuzzleFlash.Enabled = false
		SFX:Play("Pew")
		task.wait(_G.time(fireRate))
	--end
end

function SafetyBot:Die()
	self.Animator:Play("Die", nil, true)
	SFX:Play("Robodeath")
	task.wait(_G.time(2.0))
	Tw33n.tweenDescendantsOfClass(self.Model, "BasePart", TweenInfo.new(), { Transparency = 1 })
end

return SafetyBot