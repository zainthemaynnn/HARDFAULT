local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Beam = require(ReplicatedStorage.Effects.Beam)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)
local Tw33n = require(ReplicatedStorage.Util.Tw33n)

local TwoTank = {}
TwoTank.__index = TwoTank

TwoTank.Projectile = Projectiles.BlueOrb
TwoTank.LaserCastParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "NPCProjectile"
	return params
end)()

function TwoTank.new(sink: any, model: Model)
	local self = setmetatable({}, TwoTank)

	self.Model = model
	self.Turrets = {
		[1] = self.Model:FindFirstChild("LBase"),
		[2] = self.Model:FindFirstChild("RBase"),
	}
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.CastBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.BlueOrb, 40))
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

	self.Laser = Beam.new(Instance.new("Beam", self.Model))

	self.Sink = sink

	return self
end

function TwoTank:Spawn(...)
	SpawnIndicator.teleport(...)
end

function TwoTank:TakeDamage(dmg: any)
	self.Sink:Get("TakeDamage"):FireServer(dmg)
end

function TwoTank:Stomp(
	turret: number,
	speed: number,
	count: number,
	delay: number
)
	self.Animator:Play(if turret == 1 then "LStomp" else "RStomp", _G.time(delay))
	task.wait(_G.time(delay))
	for _, dir in pairs(Projectiles.VecTools.circle(count)) do
		self.Caster:Fire(self.Turrets[turret].Position, dir, speed, self.CastBehavior)
	end
	SFX:Play("Bass")
end

function TwoTank:LaserSpin(speed: number, delay: number)
	task.wait(_G.time(delay))
	self.Laser:SetEnabled(true)
	local a = 0
	self.LaserConn = RunService.Heartbeat:Connect(function(dt)
		a += dt * speed
		if a >= math.pi*2 then
			if not self.LaserConn then return end
			self.LaserConn:Disconnect()
			self.LaserConn = nil
			self.Laser:SetEnabled(false)
			return
		end
		local dir = Projectiles.VecTools.fromAngle(a)
		self.Laser:VisualRaycast(self.Model.PrimaryPart.Position, dir, self.LaserCastParams)
	end)
end

function TwoTank:DualStomp(
	speed: number,
	count: number,
	delay: number
)
	print(speed, count, delay)
	self.Animator:Play("DualStomp", _G.time(delay))
	task.wait(_G.time(delay))
	for i=1,2 do
		for _, dir in pairs(Projectiles.VecTools.circle(count)) do
			self.Caster:Fire(self.Turrets[i].Position, dir, speed, self.CastBehavior)
		end
	end
	SFX:Play("Bass")
end

function TwoTank:Die()
	if self.LaserConn then self.LaserConn:Disconnect() end
	local visor = self.Model.Visor
	SFX:Play("Buzzer")
	for _=1,3 do
		visor.Material = Enum.Material.Neon
		visor.SurfaceLight.Enabled = true
		task.wait(_G.time(0.25))

		visor.Material = Enum.Material.SmoothPlastic
		visor.SurfaceLight.Enabled = false
		task.wait(_G.time(0.25))
	end
	task.wait(_G.time(0.5))
	SFX:Play("Boom")
	Tw33n.tweenDescendantsOfClass(self.Model, "BasePart", TweenInfo.new(), { Transparency = 1 })
end

return TwoTank