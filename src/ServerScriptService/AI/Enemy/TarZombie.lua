--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local PathfindingService = game:GetService("PathfindingService")
local HTTP = game:GetService("HttpService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local Creep = require(AI.Hazard.Creep)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local DETECTION_RADIUS = 60.0
local WALKSPEED = 8.0
local SLASH_RANGE = 3.0
local SLASH_DURATION = 1.0
local SPAWN_DELAY = 3.0
local PATH_COMPUTE_COOLDOWN = 3.0

local TarZombie = {}
TarZombie.__index = TarZombie
TarZombie.Name = "TarZombie"
TarZombie.BaseModel = ServerStorage.Enemies.TarZombie
for _, p in pairs(TarZombie.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
TarZombie.Behavior = BHTCreator:Create(TarZombie.BaseModel.TarZombie)
TarZombie.SinkService = Sink:CreateService("TarZombie", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Slash",
	"SlashHit",
	"Die",
})

function TarZombie.new()
	local self = setmetatable({}, TarZombie)

	-- meta
	self.HP = 100
	self.WalkSpeed = WALKSPEED

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

	self.Sink["TakeDamage"]:Connect(function(player: Player, dmg: number)
		self.HP -= dmg
		print(self.HP)
		if self.HP <= 0 then
			print("oof")
			self:Die()
		end
	end)

	self.Sink["SlashHit"]:Connect(function(_, humanoid: Humanoid)
		print("hit")
		humanoid:TakeDamage(50)
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

function TarZombie:Spawn(pos: Vector3)
	self.Sink["Spawn"]:FireAllClients(self.Model, SPAWN_DELAY)
	task.wait(_G.time(SPAWN_DELAY))
	self.Model.Parent = workspace
	self.Model:SetPrimaryPartCFrame(cf)
	self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
end

function TarZombie:Track()
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

function TarZombie:MoveTo(pos: Vector3)
	self.Sink["Run"]:FireAllClients()
	self.RigMover:MoveTo(pos)
end

function TarZombie:LookAt(pos: Vector3)
	self.RigMover:LookAt(pos)
end

function TarZombie:CheckInMeleeRange()
	return self.TargetDistance < SLASH_RANGE
end

function TarZombie:Melee()
	self.Attacking = true
	self.RigMover:LookAt(self.Target.Character.PrimaryPart.Position)
	self.RigMover:Stop()
	self.Sink["Slash"]:FireAllClients(SLASH_DURATION)
	task.wait(_G.time(SLASH_DURATION))
	self.Attacking = false
end

function TarZombie:Die()
	self.Sink["Die"]:FireAllClients()
	Creep.new(self.Model.LeftFoot.Position, 5, 3, 3)
	self:Destroy()
end

function TarZombie:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return TarZombie