local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)
local Tw33n = require(ReplicatedStorage.Util.Tw33n)

local Assault = {}
Assault.__index = Assault

Assault.MuzzleFlash = (function()
	local light = Instance.new("PointLight")
	light.Color = BrickColor.new("Electric blue").Color
	light.Enabled = false
	return light
end)()

function Assault.new(sink: any, model: Model)
	local self = setmetatable({}, Assault)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

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

function Assault:TakeDamage(dmg: any)
	SFX:Play("Metal 1")
	self.Sink:Get("TakeDamage"):FireServer(dmg)
end

function Assault:Run(enable: boolean)
	if enable then
		self.Animator:PlayIfNotPlaying("Run")
	else
		self.Animator:Stop("Run")
	end
end

-- standard assult rifle attack
function Assault:Spray(
	target: Player,
	speed: number,
	duration: number,
	fireRate: number,
	spread: number,
	seed: number
)
	local rng = Random.new(seed)
	for _=1, duration/fireRate do
		self.Caster:Fire(
			self.WeaponMuzzle.Position,
			Projectiles.VecTools.rotate(target.Character.PrimaryPart.Position - self.WeaponMuzzle.Position, rng:NextNumber(-spread/2, spread/2)),
			speed,
			self.CastBehavior
		)
		SFX:Play("Pew")
		task.wait(_G.time(fireRate))
	end
end

function Assault:Die()
	self.Animator:Play("Die", nil, true)
	SFX:Play("Robodeath")
	task.wait(_G.time(2.0))
	Tw33n.tweenDescendantsOfClass(self.Model, "BasePart", TweenInfo.new(), { Transparency = 1 })
end

return Assault