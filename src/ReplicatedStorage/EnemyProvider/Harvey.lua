local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Explosion = require(ReplicatedStorage.Effects.Explosion)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local localPlayer = Players.LocalPlayer

local Harvey = {}
Harvey.__index = Harvey

Harvey.Rocket = Projectiles.BlueOrb:Clone()
Harvey.Rocket.Size = Vector3.new(2,2,2)

Harvey.Flame = (function()
	local pt = Instance.new("Part")
	pt.Transparency = 1
	pt.CanCollide = false
	local emitter = Instance.new("ParticleEmitter", pt)
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Color = ColorSequence.new(BrickColor.new("Bright orange").Color)
	emitter.Rate = 2
	emitter.Speed = NumberRange.new(0)
	emitter.Lifetime = NumberRange.new(0.5)
	emitter.RotSpeed = NumberRange.new(-360, 360)
	return pt
end)()

function Harvey.new(sink: any, model: Model)
	local self = setmetatable({}, Harvey)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.WeaponMuzzle = self.Model.Pistol.Muzzle

	self.RocketCaster, self.RocketCastBehavior = Projectiles.defaultCaster(Projectiles.partcache(self.Rocket, 10))

	self.RocketCaster.RayHit:Connect(function(_: any, result: RaycastResult)
		local explosion = Explosion.new(nil, false, BrickColor.new("Electric blue").Color)
		explosion:Spawn(result.Position, 2.0, 0.5, 0.5)
		local conn do
			conn = explosion.Hit:Connect(function(colliding: {Part})
				for _, part in pairs(colliding) do
					if Projectiles.localHit(part) then
						conn:Disconnect()
						self.Sink["RocketHit"]:FireServer()
					end
				end
			end)
		end
	end)

	self.FlameCaster, self.FlameCastBehavior = Projectiles.defaultCaster(Projectiles.partcache(self.Rocket, 10))
	self.FlamethrowerCaster.RayHit:Connect(function(_: any, result: RaycastResult)
		if Projectiles.localHit(result.Instance) then
			self.Sink:Get("FlamethrowerHit"):FireServer()
		end
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.teleport)
	self.Sink:Get("Shoot"):Connect(function(...) self:Shoot(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function Harvey:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function Harvey:Run(enable: boolean)
	if enable then
		self.Animator:Play("Run")
	else
		self.Animator:Stop("Run")
	end
end

function Harvey:Rocket(target: Player, speed: number, delay: number)
	local caster = self.RocketCaster
	local castBehavior = self.RocketCasterBehavior

	task.wait(_G.time(delay))

	local pos0 = self.WeaponMuzzle.Position
	local dir = (target.Character.PrimaryPart.Position - pos0).Unit * Vector3.new(1, 0, 1)
	caster:Fire(pos0, dir, speed, castBehavior)
end

function Harvey:Missiles(target: Player, speed: number, count: number, fireRate: number, delay: number)
	local caster = self.RocketCaster
	local castBehavior = self.RocketCasterBehavior

	task.wait(_G.time(delay))

	-- calculate a horizontal acceleration that will reach the target point from current position
	local cf0 = self.WeaponMuzzle.CFrame
	local diff = cf0:PointToObjectSpace(target.Character.PrimaryPart.Position)
	local dy = -diff.Z
	local t = dy / speed
	local dx = diff.X
	local ax = (2*dx)/t^2
	local a = cf0:VectorToWorldSpace(Vector3.new(ax, 0, 0))

	local pos0 = self.WeaponMuzzle.Position
	local dir = (target.Character.PrimaryPart.Position - pos0).Unit * Vector3.new(1, 0, 1)
	local cast = caster:Fire(pos0, dir, speed, castBehavior)
	cast:SetAcceleration(a)
end

-- RAMBOOO
function Harvey:Spray(target: Player, speed: number, duration: number, fireRate: number, delay: number)
	local caster = self.RocketCaster
	local castBehavior = self.RocketCasterBehavior

	task.wait(_G.time(delay))

	for _=1,duration/fireRate do
		local pos0 = self.WeaponMuzzle.Position
		local dir = (target.Character.PrimaryPart.Position - pos0).Unit * Vector3.new(1, 0, 1)
		caster:Fire(pos0, dir, speed, castBehavior)
		task.wait(_G.time(fireRate))
	end
end

function Harvey:Burn(target: Player, duration: number)
	local caster = self.FlamethrowerCaster
	local castBehavior = self.FlamethrowerCastBehavior

	RunService.Heartbeat:Connect(function()
		local pos0 = self.WeaponMuzzle.Position
		local dir = self.WeaponMuzzle.CFrame.LookVector
		caster:Fire(pos0, dir, 8.0, castBehavior)
	end)
end

function Harvey:AirStrike(radius: number, warning: number, fireRate: number, coordinates: {Vector3}, delay: number)
	task.wait(_G.time(delay))
	for _, pos in pairs(coordinates) do
		local p = Instance.new("Part")
		p.Position = pos
		p.Anchored = true
		p.CanCollide = false
		task.delay(warning, function()
			p:Destroy()
			local explosion = Explosion.new(self.ExplodeParams, false, BrickColor.new("Electric blue").Color)
			explosion.Hit:Connect(function(colliding: {Part})
				for _, part in pairs(colliding) do
					if Projectiles.localHit(part) then
						self.Sink["AirstrikeHit"]:FireServer(localPlayer)
					end
				end
			end)
		end)
		task.wait(_G.time(fireRate))
	end
end

function Harvey:Die()
	-- body
end

return Harvey