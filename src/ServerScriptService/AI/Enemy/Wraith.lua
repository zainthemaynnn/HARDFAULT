--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local HTTP = game:GetService("HttpService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local CharControl = require(ServerScriptService.Loadout.CharControl)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local DETECTION_RADIUS = 60.0
local WALKSPEED = 8.0
local SLASH_RANGE = 3.0
local SLASH_DURATION = 1.0
local SPAWN_DELAY = 3.0

local Wraith = {}
Wraith.__index = Wraith
Wraith.Name = "Wraith"
Wraith.SinkService = Sink:CreateService("Wraith", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Slash",
	"SlashHit",
	"Die",
})
--[[Wraith.BaseModel = ServerStorage.Enemies.Wraith
Wraith.ScytheModel = ServerStorage.Accessories.Scythe

for _, p in pairs(Wraith.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Wraith.Behavior = BHTCreator:Create(Wraith.BaseModel.Wraith)
Sink:CreateService("Wraith")

function Wraith.new()
	local self = setmetatable({}, Wraith)

	-- meta
	self.Name = "Wraith_" .. HTTP:GenerateGUID(false)
	self.HP = 100
	self.WalkSpeed = WALKSPEED

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()
	self.Scythe = self.ScytheModel:Clone()
	CharControl.addCustomAccessory(self.Model, self.Scythe)

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)

	-- combat
	self.Sink = Sink:Relay(
		"Wraith",
		self.Name,
		{
			"Spawn",
			"TakeDamage",
			"Run",
			"Slash",
			"SlashHit",
			"Die",
		},
		self.Model
	)

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

function Wraith:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.wait(_G.time(SPAWN_DELAY))
	self.Model.Parent = workspace
	self.Model:SetPrimaryPartCFrame(cf)
	self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
end

function Wraith:Track()
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

function Wraith:MoveTo(pos: Vector3)
	self.RigMover:MoveTo(pos)
end

function Wraith:LookAt(pos: Vector3)
	self.RigMover:LookAt(pos)
end

function Wraith:CheckInMeleeRange()
	return self.TargetDistance < SLASH_RANGE
end

function Wraith:Melee()
	self.Attacking = true
	self.RigMover:LookAt(self.Target.Character.PrimaryPart.Position)
	self.RigMover:Stop()
	self.Sink["Slash"]:FireAllClients(SLASH_DURATION)
	task.wait(_G.time(SLASH_DURATION))
	self.Attacking = false
end

function Wraith:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function Wraith:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end--]]

return Wraith