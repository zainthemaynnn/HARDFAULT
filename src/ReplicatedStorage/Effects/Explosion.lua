local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local HitReg = require(ReplicatedStorage.HitReg)
local Signal = require(ReplicatedStorage.Packages.Signal)

local Explosion = {}
Explosion.__index = Explosion

local DEFAULT_COLOR = BrickColor.new("Institutional white").Color

Explosion.DefaultPart = (function()
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.Material = Enum.Material.Neon
	part.CanCollide = false
	part.Size = Vector3.new()
	PhysicsService:SetPartCollisionGroup(part, "NPCProjectile")
	return part
end)()
Explosion.DefaultParams = (function()
	local params = OverlapParams.new()
	params.CollisionGroup = "NPCProjectile"
	return params
end)()

function Explosion.new(
	overlapParams: OverlapParams?,
	repeatableCollisions: boolean?,
	color: Color3?
)
	local self = setmetatable({}, Explosion)
	self.Part = self.DefaultPart:Clone()
	self.Part.Color = color or DEFAULT_COLOR
	self.OverlapParams = overlapParams or self.DefaultParams
	self.RepeatableCollisions = repeatableCollisions or false
	self.Colliding = {}
	self.Blasted = Signal.new()
	self.Hit = Signal.new()
	self.Finished = Signal.new()
	return self
end

function Explosion:CheckBounds(exp: any, subjSet: {any})
	subjSet = subjSet or {}

	self.Colliding = workspace:GetPartBoundsInRadius(exp.Position, exp.Radius, self.OverlapParams)
	local subjects = {}
	for _, p in pairs(self.Colliding) do
		local subject = HitReg:TryGet(p)
		if subject and not subjSet[subject] then
			subjects[#subjects+1] = subject
			subjSet[subject] = true
		end
		if not self.RepeatableCollisions then
			table.insert(self.OverlapParams.FilterDescendantsInstances, p)
		end
	end
	if #subjects > 0 then
		self.Hit:Fire(exp, subjects)
	end
end

function Explosion:Spawn(
	pos: Vector3,
	rad: number,
	duration: number?,
	fade: number?
)
	duration = duration or 1.0
	fade = fade or 0.5

	local exp = {
		Position = pos,
		Radius = rad,
	}

	self.Blasted:Fire(exp)

	local subjSet = {}
	local part = self.Part:Clone()
	local twExpand = TweenService:Create(
		part,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Size = Vector3.new(rad*2, rad*2, rad*2),
		}
	)

	local twFade = TweenService:Create(
		part,
		TweenInfo.new(fade, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{
			Transparency = 1,
		}
	)

	part.Position = pos
	part.Parent = workspace
	twExpand:Play()

	twExpand.Completed:Connect(function()
		self:CheckBounds(exp, if self.RepeatableCollisions then subjSet else nil)
		self.Finished:Fire(exp)
		twFade:Play()
		twFade.Completed:Connect(function()
			part:Destroy()
		end)
	end)

	local conn; local t = 0 do
		conn = RunService.Heartbeat:Connect(function(dt: number)
			t += dt
			if t >= duration then return conn:Disconnect() end
			self:CheckBounds({
				Position = pos,
				Radius = part.Size.X/2,
			}, if self.RepeatableCollisions then subjSet else nil)
		end)
	end
end

function Explosion:Destroy()
	self.Part:Destroy()
	self.Hit:DisconnectAll()
	self.Finished:DisconnectAll()
end

return Explosion