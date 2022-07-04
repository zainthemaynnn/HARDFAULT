local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Explosion = require(ReplicatedStorage.Effects.Explosion)
local Projectiles = require(ReplicatedStorage.Projectiles)
local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)
local Tw33n = require(ReplicatedStorage.Util.Tw33n)

local Dancer = {}
Dancer.__index = Dancer

Dancer.Projectile = Projectiles.RedOrb

function Dancer.new(sink: any, model: Model)
	local self = setmetatable({}, Dancer)

	self.Model = model
	self.Size = self.Model:GetExtentsSize()
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)
	self.RcParams = RaycastParams.new()
	self.RcParams.FilterDescendantsInstances = {self.Model}

	self.PCache = Projectiles.partcache(self.Projectile, 100)
	self.Caster, self.CastBehavior = Projectiles.caster(self.PCache)
	self.Caster.RayHit:Connect(function(cast: any, result: RaycastResult)
		if Projectiles.localHit(result.Instance) then
			self.Sink:Get("ReturnHit"):FireServer(cast.Damage)
		end
	end)

	self.HitboxL = RaycastHitbox.new(self.Model.LBlade)
	self.HitboxR = RaycastHitbox.new(self.Model.RBlade)
	self.HitboxL.OnHit:Connect(function(hit: Part)
		if Projectiles.localHit(hit) then
			self.Sink:Get("SpinHit"):FireServer()
			self.HitboxL:HitStop()
			self.HitboxL:HitStart()
		end
	end)
	self.HitboxR.OnHit:Connect(function(hit: Part)
		if Projectiles.localHit(hit) then
			self.Sink:Get("SpinHit"):FireServer()
			self.HitboxL:HitStop()
			self.HitboxL:HitStart()
		end
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.smoke)
	self.Sink:Get("Spin"):Connect(function(...) self:Spin(...) end)
	self.Sink:Get("EndSpin"):Connect(function(...) self:EndSpin(...) end)
	self.Sink:Get("ReturnOrb"):Connect(function(...) self:ReturnOrb(...) end)
	self.Sink:Get("Bomb"):Connect(function(...) self:Bomb(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function Dancer:TakeDamage(dmg: any, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(dmg, dealer)
end

function Dancer:ReturnOrb(dmg: any, dir: Vector3)
	self.Caster:FireWithRadius(
		self.Model.PrimaryPart.Position,
		dir,
		dmg.Velocity.Magnitude,
		self.CastBehavior,
		dmg.Radius
	)
end

function Dancer:Spin()
	self.Animator:Play("Spin")
	self.HitboxL:HitStart()
	self.HitboxR:HitStart()
end

function Dancer:EndSpin()
	self.Animator:Stop("Spin")
	self.HitboxL:HitStop()
	self.HitboxR:HitStop()
end

function Dancer:Bomb(bomb: Part, radius: number, timeout: number)
	bomb.Position = workspace:Raycast(self.Model.PrimaryPart.Position, -Vector3.yAxis * 999, self.RcParams).Position

	task.wait(_G.time(timeout))

	local explosion = Explosion.new(self.BombExplodeParams, false, BrickColor.new("Crimson").Color)
	explosion:Spawn(bomb.Position, radius, 0.0, 0.5)
	local hitConn do
		hitConn = explosion.Hit:Connect(function(colliding: {Part})
			for _, p in pairs(colliding) do
				if Projectiles.localHit(p) then
					hitConn:Disconnect()
					self.Sink:Get("BombHit"):FireServer(Players.LocalPlayer)
				end
			end
		end)
	end

	bomb:Destroy()
	SFX:Play("Pop")
end

function Dancer:Die()
	self.Animator:Play("Die", nil, true)
	task.wait(_G.time(2.0))
	Tw33n.tweenDescendantsOfClass(self.Model, "BasePart", TweenInfo.new(), { Transparency = 1 })
end

return Dancer