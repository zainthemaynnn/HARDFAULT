local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local CameraShaker = require(ReplicatedStorage.Effects.CameraShaker)
local CEnum = require(ReplicatedStorage.CEnum)
local Explosion = require(ReplicatedStorage.Effects.Explosion)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local Revenant = {}
Revenant.__index = Revenant

Revenant.Projectile = Projectiles.RedOrb

function Revenant.new(sink: any, model: Model)
	local self = setmetatable({}, Revenant)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.Tesla = self.Model.Tesla
	self.Field = Explosion.new(nil, nil, BrickColor.new("Electric blue").Color)
	self.Field.Hit:Connect(function(exp: any, subjects: {any})
		for _, subject in pairs(subjects) do
			subject:TakeDamage({
				Type = "Explosion",
				Cast = exp,
				Amount = exp.Radius*1.5,
			})
		end
	end)

	self.RBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.RedOrb, 100))
	self.BBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.BlueOrb, 100))
	self.Caster = Projectiles.caster()
	self.Caster.RayHit:Connect(function(cast: any, result: RaycastResult)
		if cast.Subject then
			cast.Subject:TakeDamage({
				Type = "Projectile",
				Cast = cast,
				Hit = result,
				Amount = 12,
			})
		end
	end)

	return self
end

function Revenant:Spawn(...)
	SpawnIndicator.smoke(...)
	SFX:Play("World 1:1")
	task.wait(_G.time(1.0))
	SFX:Play("Screech 1")
	CameraShaker:Start(1.0, _G.time(1.0))
end

function Revenant:TakeDamage(dmg: any): string
	self.Sink:Get("TakeDamage"):FireServer(dmg)
	return CEnum.HitResult.Success
end

function Revenant:StartField(radius: number, rate: number)
	self:EndField()
	local t = 0
	self.FieldConn = RunService.Heartbeat:Connect(function(dt: number)
		t += _G.time(dt)
		if t < rate then return end
		t -= rate
		self.Field:Spawn(self.Model.UpperTorso.Position, radius, 0.0, _G.time(rate)/2)
	end)
end

function Revenant:EndField()
	if self.FieldConn then
		self.FieldConn:Disconnect()
		self.FieldConn = nil
	end
	if self.ShootConn then
		self.ShootConn:Disconnect()
		self.ShootConn = nil
	end
end

function Revenant:MoveField(radius: number, rate: number, seed: number)
	self:StartField(radius, rate)
	local rng = Random.new(seed)
	self.ShootConn = self.Field.Blasted:Connect(function()
		SFX:Play("FieldMini")
		local dir = rng:NextUnitVector()*Vector3.new(1,0,1)
		for _, pos in pairs(Projectiles.VecTools.polygon(3, 1)) do
			self.Caster:Fire(
				self.Model.PrimaryPart.CFrame:PointToWorldSpace(pos),
				dir,
				_G.time(10.0),
				self.BBehavior
			)
		end
	end)
end

function Revenant:BigField(smallRad: number, bigRad: number, rate: number)
	self.Animator:Play("Charge")
	self:StartField(smallRad, rate)
	self.Field.Blasted:Wait()
	SFX:Play("FieldMini")
	self.Field.Blasted:Wait()
	SFX:Play("FieldMini")
	self:StartField(bigRad, rate*2.0)
	self.Field.Blasted:Wait()
	SFX:Play("FieldBig")
	CameraShaker:Start(1.0, _G.time(1.0))
	self:EndField()
	self.Animator:Stop("Charge")

	local n = 24
	for i=0,2 do
		for _, dir in pairs(Projectiles.VecTools.circle(n)) do
			self.Caster:Fire(
				self.Model.PrimaryPart.Position,
				Projectiles.VecTools.rotate(dir, 2*math.pi/n/2*i),
				_G.time(bigRad),
				self.BBehavior
			)
		end
		task.wait(_G.time(0.1))
	end
end

function Revenant:Trap(target: Player, radius: number, speed: number, duration: number)
	self.Animator:Play("LCast")
	for _, dir in pairs(Projectiles.VecTools.circle(8)) do
		local cast = self.Caster:Fire(target.Character.PrimaryPart.Position + dir * radius, -dir, radius/duration, self.RBehavior)
		task.delay(_G.time(duration), function() if cast.SetVelocity then cast:SetVelocity(-dir * speed) end end)
	end
	SFX:Play("Whomp")
end

function Revenant:Row(
	target: Player,
	n: number,
	maxDiff: number,
	speed: number,
	parryType: number
)
	self.Animator:Play("RCast")
	for i, pos in pairs(Projectiles.VecTools.row(n)) do
		pos = self.Model.PrimaryPart.CFrame:PointToWorldSpace(pos * maxDiff)
		self.Caster:Fire(
			pos,
			(target.Character.PrimaryPart.Position - self.Model.PrimaryPart.Position).Unit,
			_G.time(speed),
			self.RBehavior,
			if parryType == 1 then i > n/3 and i < n/3*2 else i < n/3 or i > n/3*2
		)
	end
	SFX:Play("Whomp")
end

function Revenant:Scatter(points: {any}, speed: number, standby: number)
	SFX:Play("LightBuzz")
	self.Animator:Play("DualCast")
	for _, point in pairs(points) do
		local pcache = self.RBehavior.CosmeticBulletProvider
		local pt = pcache:GetPart()
		pt.Transparency = .75
		pt.Position = point.Position
		task.delay(_G.time(standby), function()
			pcache:ReturnPart(pt)
			pt.Transparency = 0
			self.Caster:Fire(
				point.Position,
				point.Direction,
				_G.time(speed),
				self.RBehavior
			)
		end)
	end
	task.wait(_G.time(standby-1.0))
	SFX:Play("1SecChargeBoom")
	task.wait(_G.time(1.0))
	CameraShaker:Start(0.5, _G.time(0.5))
end

function Revenant:Stage2()
	SFX:Play("Screech 1")
	CameraShaker:Start(1.0, _G.time(1.0))
end

function Revenant:Die()
	SFX:Play("Pelo")
	for i=1, 5 do
		self:StartField(5.0 * i, 1.0)
		self.Field.Blasted:Wait()
		SFX:Play("FieldBig")
		CameraShaker:Start(0.5 * (1 + 3*i/5), _G.time(1.0))
	end
	self.Animator:Play("Die")
	self:Destroy()
end

function Revenant:Destroy()
	self:EndField()
end

return Revenant