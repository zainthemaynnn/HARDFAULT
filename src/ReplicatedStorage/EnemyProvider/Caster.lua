local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local localPlayer = Players.LocalPlayer

local Caster = {}
Caster.__index = Caster

Caster.Projectile = Projectiles.RedOrb

function Caster.new(sink: any, model: Model)
	local self = setmetatable({}, Caster)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.PCache = Projectiles.partcache(self.Projectile, 3)
	self.Caster, self.CastBehavior = Projectiles.caster(self.PCache, "NPCProjectile")

	self.Caster.LengthChanged:Connect(function(
		cast: any,
		origin: Vector3,
		dir: Vector3,
		dist: number,
		vel: Vector3,
		projectile: BasePart
	)
		if cast.UserData.Bursts >= 1 and cast.StateInfo.DistanceCovered >= cast.UserData.TargetDist then
			self:DetonateCast(cast, vel, projectile)
		end
	end)

	self.Caster.RayHit:Connect(function(
		cast: any,
		result: RaycastResult,
		vel: Vector3,
		projectile: BasePart
	)
		if not cast.UserData.Bursts then return end -- destroyed, I guess
		if Projectiles.localHit(result.Instance) then
			self.Sink:Get("OrbHit"):FireServer()
		end
		if cast.UserData.Bursts >= 1 then
			self:DetonateCast(cast, vel, projectile)
		end
		self.Caster.terminate(cast)
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.smoke)
	self.Sink:Get("Orb"):Connect(function(...) self:Orb(...) end)
	self.Sink:Get("BigOrb"):Connect(function(...) self:BigOrb(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function Caster:DetonateCast(cast: any, vel: Vector3, projectile: BasePart)
	for _, ndir in pairs(Projectiles.VecTools.circle(8)) do
		local ncast = self.Caster:FireWithRadius(
			projectile.Position,
			projectile.CFrame:VectorToWorldSpace(ndir),
			vel.Magnitude,
			self.CastBehavior,
			projectile.Size.X/4
		)
		ncast.RayInfo.CosmeticBulletObject.Size = projectile.Size/2
		ncast.UserData = {
			Bursts = cast.UserData.Bursts - 1,
			DDist = cast.UserData.DDist,
			TargetDist = cast.UserData.TargetDist + cast.UserData.DDist
		}
	end

	self.Caster.terminate(cast)
end

function Caster:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function Caster:LaunchProjectile(
	target: Player,
	speed: number,
	delay: number,
	radius: number,
	omega: number
): Part
	local caster = self.Caster
	local castBehavior = self.CastBehavior

	local p = self.PCache:GetPart()
	p.Size = Vector3.new(2, 2, 2)
	local conn do
		local t = 0
		conn = RunService.Heartbeat:Connect(function(dt)
			t += dt
			p.Position = self.Model.PrimaryPart.CFrame:PointToWorldSpace(
				Projectiles.VecTools.fromAngle(t*omega)*radius
			)
		end)
	end

	task.delay(delay, function()
		local pos0 = p.Position
		local pos1 = target.Character.PrimaryPart.Position
		local dir = pos1 - pos0
		local cast = caster:FireWithRadius(pos0, dir, speed, castBehavior, 1)
		cast.UserData = {
			Bursts = 1,
			DDist = 10.0,
			TargetDist = 20.0,
		}
		cast.RayInfo.CosmeticBulletObject.Size = Vector3.new(2,2,2)

		conn:Disconnect()
		self.PCache:ReturnPart(p)
	end)

	return p
end

function Caster:Orb(
	target: Player,
	speed: number,
	count: number,
	fireRate: number,
	delay: number
)
	for _=1, count do
		self:LaunchProjectile(target, speed, delay, 3, 2*math.pi/count/fireRate)
		task.wait(_G.time(fireRate))
	end
end

function Caster:BigOrb(
	target: Player,
	speed: number,
	radius: number,
	delay: number
)
	local caster = self.Caster
	local castBehavior = self.CastBehavior

	local p = self.PCache:GetPart()
	p.Size = Vector3.new()
	p.Position = self.Model.PrimaryPart.CFrame:PointToWorldSpace(Vector3.new(0, 0, -radius+1))

	local tw = TweenService:Create(
		p,
		TweenInfo.new(delay),
		{ Size = Vector3.new(radius*2, radius*2, radius*2) }
	)
	tw:Play()
	tw.Completed:Wait()

	local pos0 = p.Position
	local pos1 = target.Character.PrimaryPart.Position
	local dir = pos1 - pos0
	local cast = caster:FireWithRadius(pos0, dir, speed, castBehavior, radius)
	cast.UserData = {
		Bursts = 2,
		DDist = 10.0,
		TargetDist = 30.0,
	}
	cast.RayInfo.CosmeticBulletObject.Size = Vector3.new(radius*2, radius*2, radius*2)

	self.PCache:ReturnPart(p)
end

function Caster:Die()
	-- body
end

return Caster