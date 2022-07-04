local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local KillCopter = {}
KillCopter.__index = KillCopter

KillCopter.Projectile = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(1, 1, 1)
	pt.Shape = Enum.PartType.Ball
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	pt.BrickColor = BrickColor.new("Electric blue")
	return pt
end)()

function KillCopter.new(sink: any, model: Model)
	local self = setmetatable({}, KillCopter)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.CastBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.BlueOrb, 20))
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
	self.Sink:Get("Shoot"):Connect(function(...) self:Shoot(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function KillCopter:Spawn(...)
	SpawnIndicator.teleport(...)
	self.Animator:Play("Fly")
end

function KillCopter:TakeDamage(dmg: any)
	self.Sink:Get("TakeDamage"):FireServer(dmg)
	SFX:Play("Metal 1")
end

function KillCopter:Shoot(target: Player, speed: number, delay: number)
	task.wait(_G.time(delay))
	local caster = self.Caster
	local castBehavior = self.CastBehavior
	local pos0 = self.Model.PrimaryPart.Position
	local dir = (target.Character.PrimaryPart.Position - pos0).Unit * Vector3.new(1, 0, 1)
	caster:Fire(pos0, dir, speed, castBehavior)
	SFX:Play("Pew")
end

function KillCopter:Die()
	SFX:Play("Robodeath")
end

return KillCopter