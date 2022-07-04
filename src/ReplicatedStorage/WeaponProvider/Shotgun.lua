local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CEnum = require(ReplicatedStorage.CEnum)
local Clip = require(ReplicatedStorage.Clip)
local EnemyProvider = require(ReplicatedStorage.EnemyProvider)
local FastCast =  require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local Signal = require(ReplicatedStorage.Packages.Signal)
local VecTools = require(ReplicatedStorage.Util.VecTools)

local Shotgun = {}
Shotgun.__index = Shotgun

Shotgun.Name = "Shotgun"

Shotgun.Projectile = (function()
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

function Shotgun.new(
	sink: any,
	model: Model,
	damage: any,
	velocity: number,
	clipSize: number,
	reload: number,
	spread: number,
	count: number,
	falloff: number
)
	local self = setmetatable({}, Shotgun)

	self.Owner = nil
	self.Model = model
	self.Damage = damage
	self.Velocity = velocity
	self.Clip = Clip.new(clipSize, reload, {
		Fire = "Shotgun 1",
	})
	self.Spread = spread
	self.Count = count
	self.FallOff = falloff

	self.Sink = sink

	self.Sink:Get("Replicate"):Connect(function(...) self:Use(...) end)

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

	return self
end

function Shotgun:Use(clientPacket: any, inputState)
	if inputState ~= Enum.UserInputState.Begin then return nil end
	if not self.Clip:Poll() then return end

	local target = clientPacket.MousePos
	for i=1,self.Count do
		local a = -self.Spread/2+(i-1)*self.Spread/(self.Count-1)
		local cast = self.Caster:Fire(self.Muzzle.Position, VecTools.rotate(target - self.Muzzle.Position, a), self.Velocity, self.CastBehavior)
		local trail = cast.RayInfo.CosmeticBulletObject:FindFirstChildWhichIsA("Trail")
		if trail then trail.Enabled = true end
	end

	return target
end

return Shotgun