local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local RICOCHET_SPEED_MULTIPLIER = .8
local REVEAL_RADIUS = 6.0

local Ricochet = {}
Ricochet.__index = Ricochet

Ricochet.Projectile = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(1, 1, 1)
	pt.Shape = Enum.PartType.Ball
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	pt.BrickColor = BrickColor.new("Bright red")
	return pt
end)()

Ricochet.DetectionParams = (function()
	local params = OverlapParams.new()
	params.CollisionGroup = "NPCSensProjectile"
	return params
end)()

function Ricochet.new(sink: any, model: Model)
	local self = setmetatable({}, Ricochet)

	self.Model = model
	self.Parts = {}
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= self.Model.PrimaryPart then
			table.insert(self.Parts, p)
		end
	end
	self.Tweens = {}
	self.Hidden = false

	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.WeaponMuzzle = self.Model.Pistol.Muzzle

	self.RevolverCaster = FastCast.new()
	self.RevolverCache = PartCache.new(self.Projectile, 10, Instance.new("Folder", workspace))
	self.RevolverCastBehavior = (function()
		local behavior = FastCast.newBehavior()
		behavior.RaycastParams = RaycastParams.new()
		behavior.RaycastParams.CollisionGroup = "NPCProjectile"
		behavior.CosmeticBulletProvider = self.RevolverCache
		return behavior
	end)()

	self.RevolverCaster.LengthChanged:Connect(function(
		cast: any,
		origin: Vector3,
		dir: Vector3,
		dist: number,
		vel: Vector3,
		projectile: BasePart
	)
		projectile.Position = origin + dir * dist
	end)

	self.RevolverCaster.RayHit:Connect(function(
		cast: any,
		result: RaycastResult,
		vel: Vector3,
		projectile: BasePart
	)
		local char = result.Instance:FindFirstAncestorWhichIsA("Model")
		if char and char == Players.LocalPlayer.Character then
			self.RevolverCache:ReturnPart(projectile)
			self.Sink:Get("RevolverHit"):FireServer()
		else
			self.RevolverCache:ReturnPart(projectile)
			if not cast.UserData.Ricochet then
				--https://math.stackexchange.com/a/13263
				local rcast = self.RevolverCaster:Fire(
					result.Position,
					vel - 2 * vel:Dot(result.Normal) * result.Normal,
					vel.Magnitude*RICOCHET_SPEED_MULTIPLIER,
					self.RevolverCastBehavior
				)
				rcast.UserData.Ricochet = true
			end
		end
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.teleport)
	self.Sink:Get("Revolver"):Connect(function(...) self:Shoot(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	self.RevealCheck = RunService.Heartbeat:Connect(function()
		if #workspace:GetPartBoundsInRadius(
			self.Model.PrimaryPart.Position,
			REVEAL_RADIUS,
			self.DetectionParams
		) > 0 then
			if self.Hidden then
				self:Reveal()
			end
		elseif not self.Hidden then
			self:Hide()
		end
	end)

	return self
end

function Ricochet:TakeDamage(amount: any, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function Ricochet:Run(enable: boolean)
	if enable then
		self.Animator:Play("Run")
	else
		self.Animator:Stop("Run")
	end
end

-- fire quick ricocheting bullet, temporarily revealing location
function Ricochet:Shoot(target: Player, speed: number, offset: number, delay: number)
	local function rotateVec(vec: Vector3, angle: number)
		return CFrame.fromAxisAngle(Vector3.yAxis, angle):VectorToWorldSpace(vec)
	end

	local caster = self.RevolverCaster
	local castBehavior = self.RevolverCastBehavior
	local pos0 = self.WeaponMuzzle.Position
	local dir = rotateVec((target.Character.PrimaryPart.Position - pos0).Unit * Vector3.new(1, 0, 1), offset)

	task.wait(_G.time(delay))

	local cast = caster:Fire(pos0, dir, speed, castBehavior)
	cast.UserData.Ricochet = false

	self:Reveal()
	self:Hide()
end

function Ricochet:Reveal()
	self.Hidden = false
	for _, tw in pairs(self.Tweens) do tw:Cancel() end
	for _, p in pairs(self.Parts) do
		p.Transparency = .2
	end
end

function Ricochet:Hide()
	self.Hidden = true
	for i, p in pairs(self.Parts) do
		local tw = TweenService:Create(p, TweenInfo.new(), { Transparency = 1 })
		tw:Play()
		table.insert(self.Tweens, tw)
		local conn do
			conn = tw.Completed:Connect(function()
				conn:Disconnect()
				if tw then tw:Destroy() end
				self.Tweens[i] = nil
			end)
		end
	end
end

function Ricochet:Die()
	-- body
end

function Ricochet:Destroy()
	self.Sink:Destroy()
	self.Animator:Destroy()
	self.RevealCheck:Disconnect()
	for _, tw in pairs(self.Tweens) do tw:Destroy() end
end

return Ricochet