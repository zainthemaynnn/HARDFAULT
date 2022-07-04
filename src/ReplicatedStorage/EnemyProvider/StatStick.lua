local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local StatStick = {}
StatStick.__index = StatStick

StatStick.Orb = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(2, 2, 2)
	pt.Shape = Enum.PartType.Ball
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	pt.BrickColor = BrickColor.new("Really red")
	return pt
end)()

function StatStick.new(sink: any, model: Model)
	local self = setmetatable({}, StatStick)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.Caster = FastCast.new()
	self.Cache = PartCache.new(self.Orb, 100, Instance.new("Folder", workspace))
	self.CastBehavior = (function()
		local behavior = FastCast.newBehavior()
		behavior.RaycastParams = RaycastParams.new()
		behavior.RaycastParams.CollisionGroup = "NPCProjectile"
		behavior.CosmeticBulletProvider = self.Cache
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
		projectile.Size = Vector3.new(2, 2, 2)
		self.OrbCache:ReturnPart(projectile)
		local char = result.Instance:FindFirstAncestorWhichIsA("Model")
		if char and char == Players.LocalPlayer.Character then
			self.Sink:Get("OrbHit"):FireServer(char:FindFirstChildWhichIsA("Humanoid"))
		end
	end)

	self.StickMover = FastCast.new()
	self.StickCache = PartCache.new(self.Orb, 100, Instance.new("Folder", workspace))
	self.StickCastBehavior = (function()
		local behavior = FastCast.newBehavior()
		behavior.RaycastParams = RaycastParams.new()
		behavior.RaycastParams.CollisionGroup = "NPCProjectile"
		behavior.CosmeticBulletProvider = self.StickCache
		return behavior
	end)()

	self.StickCaster.LengthChanged:Connect(function(
		cast: any,
		origin: Vector3,
		dir: Vector3,
		dist: number,
		vel: Vector3,
		projectile: BasePart
	)
		projectile.Position = origin + dir * dist
		if dist >= cast.UserData.TargetDist then
			local userData = {
				TargetDist = cast.UserData.TargetDist + cast.UserData.FireRateStuds,
				FireRateStuds = cast.UserData.FireRateStuds,
			}
			local cross = vel:Cross(Vector3.yAxis)
			local cast0 = self.Caster:Fire(origin, cross, vel.Magnitude, self.CastBehavior)
			cast0.UserData = userData
			local cast1 = self.Caster:Fire(origin, -cross, vel.Magnitude, self.CastBehavior)
			cast1.UserData = userData
		end
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.smoke)
	self.Sink:Get("Clockwork"):Connect(function(...) self:Clockwork(...) end)
	self.Sink:Get("Radial"):Connect(function(...) self:Radial(...) end)
	self.Sink:Get("Stream"):Connect(function(...) self:Stream(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function StatStick:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function StatStick:Fire(target: Player, speed: number, delay: number)
	task.wait(_G.time(delay))
	local pos0 = self.Model.PrimaryPart.Position
	local pos1 = target.Character.PrimaryPart.Position
	self.Caster:Fire(pos0, pos1 - pos0, speed, self.CastBehavior)
end

function StatStick:Box(
	coords: {{Vector3}},
	speed: number,
	fireRate: number
)
	for _, row in pairs(coords) do
		local a, b, dir = table.unpack(row)
		for t=0,1,1/(a - b).Magnitude/2 do
			self.Caster:Fire(a:Lerp(b, t), dir, speed, self.CastBehavior)
		end
		task.wait(_G.time(fireRate))
	end
end

function StatStick:Spawner(
	stick: Model,
	pos: Vector3,
	speed: number,
	bursts: {{Vector3}},
	fireRate: number
)
	stick:MoveTo(pos)
	for _, burst in pairs(bursts) do
		for _, dir in pairs(burst) do
			self.Caster:Fire(pos, dir, speed, self.CastBehavior)
		end
		task.wait(_G.time(fireRate))
	end
end

function StatStick:Control(
	stick: Model,
	target: Player,
	speed: number
)
	local pos0 = stick.PrimaryPart.Position
	local pos1 = target.Character.PrimaryPart.Position
	self.StickMover:Fire(pos0, pos1 - pos0, speed, self.StickCastBehavior)
end

function StatStick:Teleport(position: number)
	-- body
end

function StatStick:Die()
	-- body
end

return StatStick