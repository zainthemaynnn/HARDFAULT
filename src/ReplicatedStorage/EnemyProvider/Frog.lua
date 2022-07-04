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

local Frog = {}
Frog.__index = Frog

Frog.Projectile = Projectiles.RedOrb

function Frog.new(sink: any, model: Model)
	local self = setmetatable({}, Frog)
	print("created")

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.PCache = PartCache.new(self.Projectile, 100, Instance.new("Folder", workspace.Junk))
	self.Caster, self.CastBehavior = Projectiles.defaultCaster(self.PCache)
	self.Caster.RayHit:Connect(function(
		cast: any,
		result: RaycastResult,
		vel: Vector3,
		projectile: BasePart
	)
		self.PCache:ReturnPart(projectile)
		if Projectiles.localHit(result.Instance) then
			self.Sink:Get("CroakHit"):FireServer(Players.LocalPlayer)
		end
	end)

	self.Caster.CastTerminating:Connect(function(cast: any)
		self.PCache:ReturnPart(cast.RayInfo.CosmeticBulletObject)
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.smoke)
	self.Sink:Get("Croak"):Connect(function(...) self:Croak(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function Frog:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function Frog:Croak(
	speed: number,
	maxDist: number,
	directions: {Vector3},
	standby: {number},
	delay: number
)
	task.wait(_G.time(delay))

	local caster = self.Caster
	local castBehavior = self.CastBehavior
	local pos0 = self.Model.PrimaryPart.Position
	local cf0 = self.Model.PrimaryPart.CFrame
	local maxT = 2*maxDist/speed

	for i=1,#directions do
		task.defer(function()
			local dir = cf0:VectorToWorldSpace(directions[i].Unit)
			local dist = directions[i].Magnitude
			local a = dir * (-speed^2/(2*dist)) -- v^2 = u^2+2as
			local t = speed/a.Magnitude -- v = u+at

			local cast = caster:Fire(pos0, dir, speed, castBehavior)
			cast:SetAcceleration(a)

			task.wait(_G.time(t))
			-- setting velocity to zero ends the cast, sooo...
			cast:SetVelocity(Vector3.new(1e-3, 1e-3, 1e-3))
			cast:SetAcceleration(Vector3.new())

			task.wait(_G.time(maxT - t + standby[i]))
			if cast then cast:Terminate() end
		end)
	end
end

function Frog:Teleport(position: number)
	-- body
end

function Frog:Die()
	-- body
end

return Frog