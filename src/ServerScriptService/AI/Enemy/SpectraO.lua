--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local HTTP = game:GetService("HttpService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local RigMover = require(AI.RigMover)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local Creep = require(AI.Hazard.Creep)
local Sink = require(ReplicatedStorage.Sink)

local DETECTION_RADIUS = 60
local WALKSPEED = 3
local SPAWN_DELAY = 3.0
local SPILL_COOLDOWN = 1
local SPILL_SIZE_MIN = 5
local SPILL_SIZE_MAX = 8

local SpectraO = {}
SpectraO.__index = SpectraO
SpectraO.Name = "SpectraO"
SpectraO.BaseModel = ServerStorage.Enemies.SpectraO
for _, p in pairs(SpectraO.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
SpectraO.Behavior = BHTCreator:Create(SpectraO.BaseModel.SpectraO)
SpectraO.SinkService = Sink:CreateService("SpectraO", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Die",
})

function SpectraO.new(room)
	local self = setmetatable({}, SpectraO)

	-- meta
	self.HP = 100
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)

	-- combat
	self.Sink = Sink:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	-- AI
	self.Blackboard = {
		Attacking = false,
		AtkFinished = false,
		Target = nil,
		TargetDistance = nil,
		SpillReady = true,
	}
	self.AILoop = nil

	return self
end

function SpectraO:Spawn(pos: Vector3)
	self.Sink["Spawn"]:FireAllClients(self.Model, SPAWN_DELAY)
	task.wait(_G.time(SPAWN_DELAY))
	self.Model.Parent = workspace
	self.Model:SetPrimaryPartCFrame(cf)
	self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
end

function SpectraO:Track()
	local player = nil
	local dist = DETECTION_RADIUS
	for _, p in pairs(Players:GetPlayers()) do
		local char = p.Character
		if not char then continue end
		local pdist = (self.RigMover:ToLevel(char.PrimaryPart.Position) - self.Model.PrimaryPart.Position).Magnitude
		if pdist < dist and pdist < DETECTION_RADIUS then
			dist = pdist
			player = p
		end
	end

	self.Blackboard.Target = player
	self.Blackboard.TargetDistance = dist
end

function SpectraO:MoveTo(pos: Vector3)
	self.Sink["Run"]:FireAllClients()
	self.RigMover:LookAt(pos)
	self.RigMover:MoveTo(pos)
end

function SpectraO:Spill()
	Creep.new(
		self.Model.LeftFoot.Position,
		self.Rng:NextNumber(SPILL_SIZE_MIN, SPILL_SIZE_MAX),
		1,
		10,
		BrickColor.new("Deep orange").Color
	)

	self.Blackboard.SpillReady = false

	task.delay(
		SPILL_COOLDOWN,
		function() self.Blackboard.SpillReady = true end
	)
end

function SpectraO:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function SpectraO:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.CombatSink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return SpectraO