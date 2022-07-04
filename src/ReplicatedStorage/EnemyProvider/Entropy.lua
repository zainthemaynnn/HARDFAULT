local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local Entropy = {}
Entropy.__index = Entropy

Entropy.Projectile = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(1, 1, 1)
	pt.Shape = Enum.PartType.Ball
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	pt.BrickColor = BrickColor.new("Bright red")
	return pt
end)()

function Entropy.new(sink: any, model: Model)
	local self = setmetatable({}, Entropy)

	self.Model = model

	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.Caster = FastCast.new()
	self.PCache = PartCache.new(self.Projectile, 10, Instance.new("Folder", workspace))
	self.CastBehavior = (function()
		local behavior = FastCast.newBehavior()
		behavior.RaycastParams = RaycastParams.new()
		behavior.RaycastParams.CollisionGroup = "NPCProjectile"
		behavior.CosmeticBulletProvider = self.PCache
		return behavior
	end)()

	self.Caster.LengthChanged:Connect(function(
		cast: any,
		origin: Vector3,
		dir: Vector3,
		dist: number,
		vel: Vector3,
		projectile: BasePart
	)
		projectile.Position = origin + dir * dist
	end)

	self.Caster.RayHit:Connect(function(
		cast: any,
		result: RaycastResult,
		vel: Vector3,
		projectile: BasePart
	)
		self.PCache:ReturnPart(projectile)
		local char = result.Instance:FindFirstAncestorWhichIsA("Model")
		if char and char == Players.LocalPlayer.Character then
			self.Sink:Get("RadialHit"):FireServer()
		end
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.smoke)
	self.Sink:Get("Radial"):Connect(function(...) self:Radial(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function Entropy:TakeDamage(amount: any, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function Entropy:Run(enable: boolean)
	if enable then
		self.Animator:Play("Run")
	else
		self.Animator:Stop("Run")
	end
end

function Entropy:Radial(bursts: {{direction: Vector3, speed: number}}, fireRate: number)
	local caster = self.Caster
	local castBehavior = self.CastBehavior
	for _, burst in pairs(bursts) do
		for _, projectile in pairs(burst) do
			caster:Fire(self.Model.PrimaryPart.Position, projectile.direction, projectile.speed, castBehavior)
		end
		task.wait(_G.time(fireRate))
	end
end

function Entropy:Die()
	-- body
end

function Entropy:Destroy()
	self.Sink:Destroy()
	self.Animator:Destroy()
end

return Entropy