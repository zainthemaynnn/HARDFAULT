--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local HTTP = game:GetService("HttpService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local DETECTION_RADIUS = 60
local WALKSPEED = 8

local PROJECTILE_SPEED = 6
local PROJECTILE_SPREAD = 30
local PROJECTILE_COOLDOWN = 4
local TELEPORT_PROGRESS_TIME = 1.5

local SpectraG = {}
SpectraG.__index = SpectraG
SpectraG.Name = "SpectraG"
SpectraG.BaseModel = ServerStorage.Enemies.SpectraG
for _, p in pairs(SpectraG.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
SpectraG.Behavior = BHTCreator:Create(SpectraG.BaseModel.SpectraG)
SpectraG.SinkService = Sink:CreateService("SpectraG", {
	"Spawn",
	"TakeDamage",
	"Teleport",
	"Spread",
	"SpreadHit",
	"Die",
})

function SpectraG.new(room)
	local self = setmetatable({}, SpectraG)

	-- meta
	self.HP = 100
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)

	-- combat
	self.Sink = Sink:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["SpreadHit"]:Connect(function(_, humanoid: Humanoid)
		print("hit")
		humanoid:TakeDamage(20)
	end)

	self.Sink["TakeDamage"]:Connect(function(player: Player, dmg: number)
		self.HP -= dmg
		print(self.HP)
		if self.HP <= 0 then
			print("oof")
			self:Die()
		else
			self:Teleport()
		end
	end)
	-- AI
	self.Blackboard = {
		Attacking = false,
		AtkFinished = false,
		TargetLocked = false,
		Teleporting = false,
		Target = nil,
		TargetDistance = nil,
	}
	self.AILoop = nil

	return self
end

function SpectraG:Spawn(pos: Vector3)
	self.Model.Parent = workspace
	self.Model:SetPrimaryPartCFrame(cf)
	self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
end

function SpectraG:Track()
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
	if self.Blackboard.Target then
		self.Blackboard.TargetDistance = dist
	end
end

function SpectraG:Teleport()
	self.Blackboard.Teleporting = true

	-- spawn at an edge of the room
	local pos do
		local edge = self.Rng:NextInteger(1, 4)
		pos = self.Room:PointFromUDim2(
			if edge == 1 then
				UDim2.new(
					self.Rng:NextNumber(.1, .9),
					0,
					.1,
					0
				)
			elseif edge == 2 then
				UDim2.new(
					.1,
					0,
					self.Rng:NextNumber(.1, .9),
					0
				)
			elseif edge == 3 then
				UDim2.new(
					self.Rng:NextNumber(.1, .9),
					0,
					.9,
					0
				)
			elseif edge == 4 then
				UDim2.new(
					.9,
					0,
					self.Rng:NextNumber(.1, .9),
					0
				)
			else
				error("unreachable")
		)
	end

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

	self.Blackboard.Teleporting = false
end

function SpectraG:Spread()
	self.Blackboard.Attacking = true

	local pp = self.Model.PrimaryPart
	self.RigMover:LookAt(self.Blackboard.Target.Character.PrimaryPart.Position)
	self.Sink["Spread"]:FireAllClients(self.Blackboard.Target, PROJECTILE_SPEED, PROJECTILE_SPREAD)

	task.delay(
		PROJECTILE_COOLDOWN,
		function()
			self.Blackboard.Attacking = false
			self.Blackboard.AtkFinished = true
		end
	)
end

function SpectraG:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function SpectraG:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return SpectraG