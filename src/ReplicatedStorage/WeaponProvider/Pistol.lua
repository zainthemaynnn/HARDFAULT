local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Clip = require(ReplicatedStorage.Clip)
local EnemyProvider = require(ReplicatedStorage.EnemyProvider)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)

local Pistol = {}
Pistol.__index = Pistol

Pistol.Name = "Pistol"

Pistol.Bullet = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(0.4, 0.4, 0.4)
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

function Pistol.new(
	sink: any,
	model: Model,
	damage: any,
	velocity: number,
	magSize: number,
	reload: number,
	falloff: number
)
	local self = setmetatable({}, Pistol)

	self.Model = model
	self.Damage = damage
	self.Velocity = velocity
	self.FallOff = falloff

	self.Clip = Clip.new(magSize, reload, {
		Fire = "Pistol 1",
	})

	self.Sink = sink
	self.Sink:Get("Replicate"):Connect(function(...) self:Fire(...) end)

	self.Muzzle = self.Model.Muzzle

	self.CastBehavior = Projectiles.Caster.stdBehavior("PlrProjectile", Projectiles.partcache(self.Bullet, 10))
	self.Caster = Projectiles.Caster.new()
	self.Caster.RayHit:Connect(function(cast: any, result: RaycastResult)
		if cast.Subject then
			cast.Subject:TakeDamage(Projectiles.Damage.projectile(cast, result, self.Damage))
		end
	end)

	return self
end

function Pistol:Use(inputState: any, combatInfo: any)
	if self.FireLoop then
		self.FireLoop:Disconnect()
		self.FireLoop = nil
	end
	if inputState == Enum.UserInputState.Begin then
		local frate = 0.5
		local t = frate
		self.FireLoop = RunService.Heartbeat:Connect(function(dt: number)
			t += dt
			if t < frate then return end
			t -= frate
			SFX:Play("Pistol 1")
			--if not self.Clip:Poll() then return end
			local state = combatInfo:getState()
			local target = state.MousePosition
			self:Fire(Players.LocalPlayer, target)
			self.Sink:Get("Replicate"):FireServer(target)
		end)
	end
end

function Pistol:Fire(plr: Player, target: Vector3): any
	local cast = self.Caster:Fire(
		self.Muzzle.Position,
		target - self.Muzzle.Position,
		self.Velocity,
		self.CastBehavior
	)
	cast.UserData.Owner = plr
	return cast
end

return Pistol