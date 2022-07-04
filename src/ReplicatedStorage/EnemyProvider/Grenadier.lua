local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Explosion = require(ReplicatedStorage.Effects.Explosion)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local Grenadier = {}
Grenadier.__index = Grenadier

Grenadier.Projectile = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(1, 1, 1)
	pt.Shape = Enum.PartType.Ball
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	pt.BrickColor = BrickColor.new("Electric blue")
	return pt
end)()

function Grenadier.new(sink: any, model: Model)
	local self = setmetatable({}, Grenadier)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.WeaponMuzzle = self.Model.Pistol.Muzzle

	self.CastBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.BlueOrb, 10))
	self.Caster = Projectiles.Caster.new()
	self.Caster.LengthChanged:Connect(function(cast: any, pos: Vector3, dir: Vector3, dist: number, vel: Vector3)
		local cf0 = CFrame.lookAt(pos+dir*dist, pos+dir*(dist+1.0))
		vel = cf0:VectorToObjectSpace(vel)
		if cast.StateInfo.TotalRuntime >= _G.time(5.0) then
			self.Explosion:Spawn(pos+dir*dist, 4.0, 0.0, 0.5)
			Projectiles.Caster.terminate(cast)

		elseif cast.StateInfo.TotalRuntime >= cast.UserData.NextAlign then
			cast.UserData.NextAlign += 1
			local target = cast.UserData.Target.Character.PrimaryPart.Position

			-- calculate a horizontal acceleration that will reach the target point from current position
			local diff = cf0:PointToObjectSpace(target)
			if diff.Z > 0 then return end
			local dy = -diff.Z
			local t = _G.time(dy / -vel.Z)
			local dx = diff.X
			local ax = (2*dx)/t^2
			local a = cf0:VectorToWorldSpace(Vector3.new(ax, 0, 0))
			a = a.Unit * math.min(a.Magnitude, 16.0)

			cast:SetAcceleration(a)
		end
	end)

	self.Caster.RayHit:Connect(function(cast: any, result: RaycastResult)
		self.Explosion:Spawn(result.Position, 4.0, 0.0, 0.5)
	end)

	self.Explosion = Explosion.new(nil, nil, BrickColor.new("Electric blue").Color)
	self.Explosion.Hit:Connect(function(exp: any, subjects: {any})
		for _, subject in pairs(subjects) do
			subject:TakeDamage({
				Type = "Explosion",
				Cast = exp,
				Amount = exp.Radius*1.5,
			})
		end
	end)

	return self
end

function Grenadier:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function Grenadier:Spawn(...)
	SpawnIndicator.teleport(...)
end

function Grenadier:Run(enable: boolean)
	if enable then
		self.Animator:Play("Run")
	else
		self.Animator:Stop("Run")
	end
end

function Grenadier:Detonate(grenade: Part, radius: number)
	self.Explosion:Spawn(grenade.Position, radius, 0, 0.5)
	if grenade then grenade:Destroy() end
end

function Grenadier:Grenade(target: Player, speed: number)
	local pos0 = self.WeaponMuzzle.Position
	local dir = ((target.Character.PrimaryPart.Position - pos0) * Vector3.new(1, 0, 1)).Unit
	local cast = self.Caster:Fire(pos0, dir, _G.time(speed), self.CastBehavior)
	cast.UserData.NextAlign = 1
	cast.UserData.Target = target
end

function Grenadier:Die()
	self:Destroy()
end

function Grenadier:Destroy()
	self.Explosion:Destroy()
end

return Grenadier