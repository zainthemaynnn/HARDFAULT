local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CEnum = require(ReplicatedStorage.CEnum)
local Clip = require(ReplicatedStorage.Clip)
local EnemyProvider = require(ReplicatedStorage.EnemyProvider)
local FastCast =  require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local Signal = require(ReplicatedStorage.Packages.Signal)
local VecTools = require(ReplicatedStorage.Util.VecTools)

local SMG = {}
SMG.__index = SMG

SMG.Name = "SMG"

SMG.Projectile = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(0.2, 0.2, 0.2)
	pt.BrickColor = BrickColor.new("Really black")

	local att0 = Instance.new("Attachment", pt)
	att0.Position = Vector3.new(0, pt.Size.Y/1.5, 0)
	local att1 = Instance.new("Attachment", pt)
	att1.Position = Vector3.new(0, -pt.Size.Y/1.5, 0)

	local trail = Instance.new("Trail", pt)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Color = ColorSequence.new(
		BrickColor.new("Really black").Color,
		BrickColor.new("Really black").Color
	)
	trail.Transparency = NumberSequence.new(0, 1)
	trail.Lifetime = 0.2
	trail.FaceCamera = true
	trail.Enabled = false
	return pt
end)()

function SMG.new(
	sink: any,
	model: Model,
	damage: any,
	velocity: number,
	clipSize: number,
	reload: number,
	fireRate: number,
	accuracy: number,
	falloff: number
)
	local self = setmetatable({}, SMG)

	self.Owner = nil
	self.Model = model
	self.Damage = damage
	self.Velocity = velocity
	self.FireRate = fireRate
	self.Accuracy = accuracy
	self.Clip = Clip.new(clipSize, reload, {
		Fire = "SMG 1",
	})
	self.FallOff = falloff
	self.Sink = sink
	self.Sink:Get("Replicate"):Connect(function(...) self:Use(...) end)
	self.Rng = Random.new()

	self.Muzzle = self.Model.Muzzle
	self.Caster = FastCast.new()
	self.PartCache = PartCache.new(self.Projectile, 10, Instance.new("Folder", workspace))
	self.CastBehavior = (function()
		local behavior = FastCast.newBehavior()
		behavior.RaycastParams = RaycastParams.new()
		behavior.RaycastParams.CollisionGroup = "PlrProjectile"
		behavior.CosmeticBulletProvider = self.PartCache
		return behavior
	end)()

	self.Caster.LengthChanged:Connect(Projectiles.updatePosition)
	self.Caster.RayHit:Connect(function(cast: any, result: RaycastResult)
		local hit = result.Instance:FindFirstAncestorWhichIsA("Model")
		if not hit then return end
		local enemy = EnemyProvider[hit.Name]
		if not enemy then return end
		enemy:TakeDamage(self.Damage, Players.LocalPlayer)
	end)

	self.Caster.CastTerminating:Connect(function(cast: any)
		local projectile = cast.RayInfo.CosmeticBulletObject
		local trail = projectile:FindFirstChildWhichIsA("Trail")
		if trail then trail.Enabled = false end
		self.PartCache:ReturnPart(projectile)
	end)

	self.FireLoop = nil

	return self
end

function SMG:Use(clientPacket: any, inputState, hud)
	if inputState == Enum.UserInputState.Begin then
		local t = 0
		self.FireLoop = RunService.Heartbeat:Connect(function(dt: number)
			if not self.Clip:Poll() then return self.FireLoop:Disconnect() end

			local target = clientPacket.MousePos
			t += dt
			if t < self.FireRate then return end
			t -= self.FireRate

			local cast = self.Caster:Fire(
				self.Muzzle.Position,
				VecTools.rotate(target - self.Muzzle.Position, self.Rng:NextNumber(-self.Accuracy/2, self.Accuracy/2)),
				self.Velocity,
				self.CastBehavior
			)
			local trail = cast.RayInfo.CosmeticBulletObject:FindFirstChildWhichIsA("Trail")
			if trail then trail.Enabled = true end

			hud:dispatch({
				type = "Used",
			})
		end)
	else
		if self.FireLoop then self.FireLoop:Disconnect() end
	end
end

return SMG