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
local Sink = require(ReplicatedStorage.Sink)

local DETECTION_RADIUS = 60.0
local WALKSPEED = 8.0
local SPAWN_DELAY = 3.0
local TELEPORT_DELAY = 0.5
local TELEPORT_PROGRESS_TIME = 0.5
local LASER_CHARGE_TIME = 0.5
local LASER_DELAY_TIME = 0.5

local SpectraV = {}
SpectraV.__index = SpectraV
SpectraV.Name = "SpectraV"
SpectraV.BaseModel = ServerStorage.Enemies.SpectraV
for _, p in pairs(SpectraV.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
SpectraV.Behavior = BHTCreator:Create(SpectraV.BaseModel.SpectraV)
SpectraV.SinkService = Sink:CreateService("SpectraV", {
	"Spawn",
	"TakeDamage",
	"Teleport",
	"Beam",
	"BeamHit",
	"Die",
})

function SpectraV.new(room)
	local self = setmetatable({}, SpectraV)

	-- meta
	self.HP = 100
	self.WalkSpeed = WALKSPEED
	self.Room = room

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)

	-- combat
	self.Sink = Sink:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["BeamHit"]:Connect(function(_, humanoid: Humanoid)
		print("hit")
		humanoid:TakeDamage(20)
	end)

	self.Sink["TakeDamage"]:Connect(function(player: Player, dmg: number)
		self.HP -= dmg
		print(self.HP)
		if self.HP <= 0 then
			print("oof")
			self:Die()
		end
	end)

	-- AI
	self.Blackboard = {
		Attacking = false,
		AtkFinished = false,
		TargetLocked = false,
	}
	self.Target = nil
	self.TargetDistance = nil
	self.AILoop = nil

	return self
end

function SpectraV:Spawn(pos: Vector3)
	self.Sink["Spawn"]:FireAllClients(self.Model, SPAWN_DELAY)
	task.wait(_G.time(SPAWN_DELAY))
	self.Model.Parent = workspace
	self.Model:SetPrimaryPartCFrame(cf)
	self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
end

function SpectraV:Track()
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

	self.Target = player
	if self.Target then
		self.TargetDistance = dist
	end
end

function SpectraV:Teleport()
	local rng = Random.new()
	local pos = self.Room:PointFromUDim2(
		UDim2.new(rng:NextNumber(.1, .9), 0, rng:NextNumber(.1, .9), 0)
	)

	task.wait(_G.time(TELEPORT_DELAY))

	-- move it out of sight for a sec
	self.Model.Parent = nil
	self.Sink["Teleport"]:FireAllClients(
		self.Model.PrimaryPart.Position,
		self.RigMover:ToLevel(pos),
		TELEPORT_PROGRESS_TIME
	)

	task.wait(_G.time(TELEPORT_PROGRESS_TIME))

	self.Model.Parent = workspace
	self.Model:SetPrimaryPartCFrame(cf)
end

function SpectraV:Laser()
	if not self.Target then return end
	self.Blackboard.Attacking = true

	local pp = self.Model.PrimaryPart
	self.RigMover:LookAt(self.Target.Character.PrimaryPart.Position)

	self.Sink["Target"]:FireAllClients(self.Blackboard.Target, LASER_CHARGE_TIME)
	task.delay(
		LASER_CHARGE_TIME,
		function()
			self.Blackboard.TargetLocked = true
			self.Sink["Beam"]:FireAllClients(self.Blackboard.Target, LASER_DELAY_TIME)
			task.wait(_G.time(LASER_DELAY_TIME))
			self.Blackboard.TargetLocked = false
			self.Blackboard.Attacking = false
			self.Blackboard.AtkFinished = true
		end
	)
end

function SpectraV:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function SpectraV:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return SpectraV