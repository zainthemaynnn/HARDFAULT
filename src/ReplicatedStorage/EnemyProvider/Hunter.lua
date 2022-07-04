local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)
local Tw33n = require(ReplicatedStorage.Util.Tw33n)

local Hunter = {}
Hunter.__index = Hunter

Hunter.Projectile = Projectiles.BlueOrb

function Hunter.new(sink: any, model: Model)
	local self = setmetatable({}, Hunter)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.WeaponMuzzle = self.Model.Pistol.Muzzle

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

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.teleport)
	self.Sink:Get("Spread"):Connect(function(...) self:Spread(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function Hunter:TakeDamage(dmg: any)
	SFX:Play("Metal 1")
	self.Sink:Get("TakeDamage"):FireServer(dmg)
end

function Hunter:Run(enable: boolean)
	if enable then
		self.Animator:PlayIfNotPlaying("Run")
	else
		self.Animator:Stop("Run")
	end
end

function Hunter:Spread(
	target: Player,
	speed: number,
	count: number,
	spread: number,
	delay: number
)
	task.wait(_G.time(delay))

	local cf = CFrame.lookAt(self.WeaponMuzzle.Position, target.Character.PrimaryPart.Position)
	for _, dir in pairs(Projectiles.VecTools.arc(spread, count)) do
		self.Caster:Fire(cf.Position, cf:VectorToWorldSpace(dir), speed, self.CastBehavior)
	end
	SFX:Play("Pew")
end

function Hunter:Die()
	self.Animator:Play("Die", nil, true)
	SFX:Play("Robodeath")
	task.wait(_G.time(2.0))
	Tw33n.tweenDescendantsOfClass(self.Model, "BasePart", TweenInfo.new(), { Transparency = 1 })
end

return Hunter