local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Beam = require(ReplicatedStorage.Effects.Beam)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)

local LocalPlayer = Players.LocalPlayer

local SpectraG = {}
SpectraG.__index = SpectraG

SpectraG.Telepart = (function()
	local pt = Instance.new("Part")
	pt.Shape = Enum.PartType.Ball
	pt.BrickColor = BrickColor.new("Lime green")
	pt.Size = Vector3.new(2, 2, 2)
	pt.Material = Enum.Material.Neon
	pt.Anchored = true
	pt.CanCollide = false
	return pt
end)()

SpectraG.Projectile = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(1, 1, 1)
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	pt.BrickColor = BrickColor.new("Lime green")
	return pt
end)()

function SpectraG.new(name, sink, model)
	local self = setmetatable({}, SpectraG)
	
	self.Sink = sink
	self.Model = model
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

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
		projectile:Destroy()
		local char = result.Instance:FindFirstAncestorWhichIsA("Model")
		if not char then return end
		if char == LocalPlayer.Character then
			self.Sink:Get("SpreadHit"):FireServer(char:FindFirstChildWhichIsA("Humanoid"))
		end
	end)

	self.Sink:Get("Spawn"):Connect(function(...) self:Spawn(...) end)
	self.Sink:Get("TakeDamage"):Connect(function(...) self:TakeDamage(...) end)
	self.Sink:Get("Teleport"):Connect(function(...) self:Teleport(...) end)
	self.Sink:Get("Spread"):Connect(function(...) self:Spread(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)
	return self
end

function SpectraG:Spawn(pos: Vector3, size: Vector3, spawnDelay: number)
	-- body
end

function SpectraG:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

-- teleport when hit
function SpectraG:Teleport(pos0: Vector3, pos1: Vector3, tpDelay: number)
	local pt = self.Telepart:Clone()
	pt.Position = pos0
	pt.Parent = workspace

	local tw = TweenService:Create(
		pt,
		TweenInfo.new(tpDelay, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
		{ Position = pos1 }
	)
	tw:Play()
	tw.Completed:Wait()
	tw:Destroy()
	pt:Destroy()
end

-- fire a fan of medium-slow projectiles
function SpectraG:Spread(target: Player, spread: number, speed: number)
	local function rotateVec(vec: Vector3, angle: number)
		return CFrame.fromAxisAngle(Vector3.yAxis, angle):VectorToWorldSpace(vec)
	end

	local caster = self.SpreadCaster
	local castBehavior = self.SpreadCastBehavior
	local pos0 = self.Model.PrimaryPart.Position

	local dir0 = (target.Character.PrimaryPart.Position - pos0).Unit
	local dir1 = rotateVec(dir0, math.rad(spread))
	local dir2 = rotateVec(dir0, math.rad(-spread))

	caster:Fire(pos0, dir0, speed, castBehavior)
	caster:Fire(pos0, dir1, speed, castBehavior)
	caster:Fire(pos0, dir2, speed, castBehavior)
end

function SpectraG:Die()
	-- body
end

return SpectraG