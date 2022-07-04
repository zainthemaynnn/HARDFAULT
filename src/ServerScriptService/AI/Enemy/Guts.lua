--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local Creep = require(ReplicatedStorage.Effects.Creep)
local Pathing = require(AI.Pathing)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local DETECTION_RADIUS = 60.0
local WALKSPEED = 8.0
local SINK_DELAY_1 = 3.0
local SINK_DELAY_2 = 3.0
local CLOUD_DURATION = 8.0
local SPAWN_DELAY = 3.0

local Guts = {}
Guts.__index = Guts
Guts.Name = "Guts"
Guts.Resistance = {
	Ballistic = .6,
	Energy = .2,
	Chemical = 2,
	Fire = -.5,
}
Guts.FlavorText = [[
Angrily regurgitates corrosive chemicals. Thankfully, they burn easily.

What's a zombie apocalypse without barfing zombies?
]]

Guts.BaseModel = ServerStorage.Enemies.Guts
for _, p in pairs(Guts.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Guts.Behavior = BHTCreator:Create(Guts.BaseModel.Guts)
Guts.SinkService = Sink:CreateService("Guts", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Spray",
	"SprayHit",
	"Cloud",
	"CloudHit",
	"Sink",
	"SinkHit",
	"Die",
})

Guts.TarProjectile = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(1, 1, 1)
	pt.Shape = Enum.PartType.Ball
	pt.CanCollide = false
	pt.Material = Enum.Material.SmoothPlastic
	pt.BrickColor = BrickColor.new("Really black")
	return pt
end)()

function Guts.new(room)
	local self = setmetatable({}, Guts)

	-- meta
	self.HP = 100
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(player: Player, dmg: number)
		self.HP -= dmg
		print(self.HP)
		if self.HP <= 0 then
			print("oof")
			self:Die()
		end
	end)

	self.Sink["CloudHit"]:Connect(function(_, humanoid: Humanoid)
		print("hit")
		humanoid:TakeDamage(10)
	end)

	-- AI
	self.AILoop = nil
	self.Blackboard = {
		Attacking = false,
		Target = nil,
		TargetDistance = nil,
	}

	return self
end

function Guts:Spawn(pos: Vector3)
	self.Sink["Spawn"]:FireAllClients(self.Model, SPAWN_DELAY)
	task.wait(_G.time(SPAWN_DELAY))
	self.Model.Parent = workspace
	self.Model:SetPrimaryPartCFrame(cf)
	Creep.new(self.Model.LeftFoot.Position, 5, 3, 3)
	self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
end

function Guts:Track()
	local plr, dist = Pathing.closestPlayer(self.Model.PrimaryPart.Position)
	self.Blackboard.Target = plr
	self.Blackboard.TargetDistance = dist
	return if plr ~= nil then 1 else 2
end

function Guts:MoveTo(pos: Vector3)
	self.Sink["Run"]:FireAllClients()
	self.RigMover:MoveTo(pos)
end

function Guts:LookAt(pos: Vector3)
	self.RigMover:LookAt(pos)
end

function Guts:Spray()
	self:LookAt(self.Blackboard.Target.Character.PrimaryPart.Position)
	local targets = {}
	for _=1,3 do
		local target = self.Model.PrimaryPart.CFrame:VectorToWorldSpace(
			Vector3.new(self.Rng:NextNumber(-5, 5), 0, self.Rng:NextNumber(-12, -8))
		)
		targets[#targets+1] = target
	end

	self.Sink["Spray"]:FireAllClients(targets, 3)
	task.wait(_G.time(3))
	for _, target in pairs(targets) do
		Creep.new(target, 3)
	end
end

function Guts:Cloud()
	self.Sink["Cloud"]:FireAllClients(8, 3, CLOUD_DURATION)
	task.wait(_G.time(3 + CLOUD_DURATION))
end

function Guts:Sink()
	local pos0 = self.Model.LeftFoot.Position
	local pos1 = self.Room:PointFromUDim2(UDim2.fromScale(self.Rng:NextNumber(0, 1), self.Rng:NextNumber(0, 1)))
	Creep.new(pos0, 4)
	task.wait(_G.time(SINK_DELAY_1))
	Creep.new(pos1, 4)
	self.Model:MoveTo(pos1)
	task.wait(_G.time(SINK_DELAY_2))
end

function Guts:Die()
	self.Sink["Die"]:FireAllClients()
	Creep.new(self.Model.LeftFoot.Position, 5, 3, 3)
	self:Destroy()
end

function Guts:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return Guts