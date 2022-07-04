local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local localPlayer = Players.LocalPlayer

-- how many rays are cast in a cone for the breath attack
local BREATH_HITBOX_FIDELITY = 5

local BoilerWorker = {}
BoilerWorker.__index = BoilerWorker

BoilerWorker.Projectile = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(1, 1, 1)
	pt.Shape = Enum.PartType.Ball
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	pt.BrickColor = BrickColor.new("Electric blue")
	return pt
end)()

function BoilerWorker.new(sink: any, model: Model)
	local self = setmetatable({}, BoilerWorker)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.WeaponMuzzle = self.Model.Pistol.Muzzle

	self.SpreadCaster = FastCast.new()
	self.SpreadCache = PartCache.new(self.Projectile, 10, Instance.new("Folder", workspace))
	self.SpreadCastBehavior = (function()
		local behavior = FastCast.newBehavior()
		behavior.RaycastParams = RaycastParams.new()
		behavior.RaycastParams.CollisionGroup = "NPCProjectile"
		behavior.CosmeticBulletProvider = self.SpreadCache
		return behavior
	end)()

	self.SpreadCaster.LengthChanged:Connect(function(
		cast: any,
		origin: Vector3,
		dir: Vector3,
		dist: number,
		vel: Vector3,
		projectile: BasePart
	)
		projectile.Position = origin + dir * dist
	end)

	self.SpreadCaster.RayHit:Connect(function(
		cast: any,
		result: RaycastResult,
		vel: Vector3,
		projectile: BasePart
	)
		self.SpreadCache:ReturnPart(projectile)
		local char = result.Instance:FindFirstAncestorWhichIsA("Model")
		if not char then return end
		if char == localPlayer.Character then
			self.Sink:Get("SpreadHit"):FireServer(char:FindFirstChildWhichIsA("Humanoid"))
		end
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.teleport)
	self.Sink:Get("Spread"):Connect(function(...) self:Spread(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function BoilerWorker:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function BoilerWorker:Run(enable: boolean)
	if enable then
		self.Animator:Play("Run")
	else
		self.Animator:Stop("Run")
	end
end

function BoilerWorker:Grenade(
	target: Player,
	speed: number,
	count: number,
	spread: number,
	delay: number
)
	task.wait(_G.time(delay))

	Projectiles.spread(
		self.SpreadCaster,
		self.SpreadCastBehavior,
		self.WeaponMuzzle.Position,
		(target.Character.PrimaryPart.Position - self.WeaponMuzzle.Position).Unit * Vector3.new(1, 0, 1),
		speed,
		count,
		spread
	)
end

function BoilerWorker:Breath(
	target: Player,
	length: number,
	spread: number,
	duration: number,
	delay: number
)
	-- body
end

function BoilerWorker:Die()
	-- body
end

return BoilerWorker