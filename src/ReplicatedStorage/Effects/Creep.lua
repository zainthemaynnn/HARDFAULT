local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PhysicsService = game:GetService("PhysicsService")

local Signal = require(ReplicatedStorage.Packages.Signal)

local Creep = {}
Creep.__index = Creep

Creep.SplotchModel = (function()
	local pt = Instance.new("Part")
	pt.Shape = Enum.PartType.Cylinder
	pt.Color = BrickColor.new("Really black").Color
	pt.Material = Enum.Material.Mud
	pt.Size = Vector3.new(0.05, 0.05, 0.05)
	-- pt.Reflectance = .2
	pt.Orientation = Vector3.new(0, 0, 90) -- make the flat part face up
	pt.CollisionGroupId = PhysicsService:GetCollisionGroupId("NPC")
	pt.Anchored = true
	return pt
end)()

local DEFAULT_PARAMS = {
	Splotches = 1,
	Lifetime = 10,
	Color = BrickColor.new("Really black").Color,
}

function Creep.new(
	position: Vector3,
	diameter: number,
	params: {any}?
)
	local splotches = params and params.Splotches or DEFAULT_PARAMS.Splotches
	local lifetime = params and params.Lifetime or DEFAULT_PARAMS.Lifetime
	local color = params and params.Color or DEFAULT_PARAMS.Color

	local self = setmetatable({}, Creep)
	self.Splotches = {}
	self.Hit = Signal.new()
	self._Container = Instance.new("Folder", workspace.Hazards)
	self._Container.Name = "Creep"

	self:CreateSplotch(position, diameter, color)

	local rng = Random.new()
	local t = 1/splotches

	task.defer(function()
		for k=1-t, 0, -t do
			local angle = rng:NextNumber(0, 2*math.pi)
			local i = rng:NextInteger(1, #self.Splotches)
			local source = self.Splotches[i]
			local ofst = diameter/2 - diameter*t*(i-1)

			self:CreateSplotch(
				source.Position + Vector3.new(math.cos(angle)*ofst, 0, math.sin(angle)*ofst),
				diameter * k,
				color,
				1 * k
			)
		end

		task.delay(_G.time(lifetime), function()
			self:Evaporate()
		end)
	end)

	return self
end

function Creep:CreateSplotch(pos: Vector3, diameter: number, color: Color3?, time: number?)
	time = time or 1

	local pt = self.SplotchModel:Clone()
	pt.Position = pos
	if color then pt.Color = color end
	pt.Parent = self._Container
	pt.Touched:Connect(function(hit: Part) self.Hit:Fire(hit) end)
	self.Splotches[#self.Splotches+1] = pt

	local tw = TweenService:Create(
		pt,
		TweenInfo.new(time),
		{ Size = Vector3.new(pt.Size.X, diameter, diameter) }
	)
	tw:Play()
	tw.Completed:Wait()
end

function Creep:Evaporate(time: number?)
	time = time or 1

	for _, splotch in pairs(self.Splotches) do
		local tw = TweenService:Create(
			splotch,
			TweenInfo.new(time),
			{ Size = Vector3.new(0.05, 0.05, 0.05) }
		)
		tw:Play()
	end

	task.delay(time, self.Destroy)
end

function Creep:Destroy()
	self._Container:Destroy()
end

return Creep