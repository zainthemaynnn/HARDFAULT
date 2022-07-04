--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local Pathing = require(AI.Pathing)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local Caster = {}
Caster.__index = Caster
Caster.Name = "Caster"
Caster.BestiaryIndex = 1
Caster.BaseHp = 100
Caster.WalkSpeed = 6.0
Caster.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
Caster.FlavorText = [[
rawr
]]

Caster.BaseModel = ServerStorage.Enemies.Caster
for _, p in pairs(Caster.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Caster.SinkService = Sink:CreateService("Caster", {
	"Spawn",
	"TakeDamage",
	"Orb",
	"OrbHit",
	"BigOrb",
	"BigOrbHit",
	"Die",
})

function Caster.new(room)
	local self = setmetatable({}, Caster)

	-- meta
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances)
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed, self.Size)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(self.Model.Caster)
	self.AILoop = nil
	self.Blackboard = EntityBlackboard.new({
		Target = false,
		TargetDistance = math.huge,
		CanOrb = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Caster:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Caster:Track()
	local plr, dist = Pathing.closestPlayer(self.Model.PrimaryPart.Position, true)
	self.Blackboard.Target = plr or false
	self.Blackboard.TargetDistance = dist
	return if self.Blackboard.Target then 1 else 2
end

function Caster:Orb()
	self.Sink["Orb"]:FireAllClients(
		self.Blackboard.Target,
		8.0,
		3,
		0.5,
		3.0
	)
	self.Blackboard:StartCooldown("CanOrb", 6.0)
	return 1
end

function Caster:BigOrb()
	self.Sink["BigOrb"]:FireAllClients(
		self.Blackboard.Target,
		8.0,
		2.0,
		3.0
	)
	self.Blackboard:StartCooldown("CanOrb", 6.0)
	return 1
end

function Caster:Die()
	self.Sink["Die"]:FireAllClients()
	if self.AILoop then self.AILoop:Disconnect() end
	self.RigMover:Destroy()
	self.Model:Destroy()
end

function Caster:Destroy()
	self.Sink:Destroy()
end

return Caster