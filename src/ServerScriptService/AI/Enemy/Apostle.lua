--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 4.0
local INITIAL_ATK_DELAY = 1.0
local FINAL_ATK_DELAY = 0.2

local Apostle = {}
Apostle.__index = Apostle
Apostle.Name = "Apostle"
Apostle.BaseHp = 300
Apostle.Resistance = {
	Ballistic = .2,
	Energy = .2,
	Chemical = 0,
	Fire = 0,
	Knockback = .5,
}
Apostle.BestiaryIndex = 10
Apostle.FlavorText = [[
Likes to spam basic attacks. Too bad it only has like, three.
]]

Apostle.BaseModel = ServerStorage.Enemies.Apostle
Apostle.Behavior = BHTCreator:Create(Apostle.BaseModel.Apostle)
Apostle.MovementParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "NPC"
	return params
end)()
Apostle.SinkService = Sink:CreateService("Apostle", {
	"Spawn",
	"Run",
	"Teleport",
	"Cross",
	"Stream",
	"TakeDamage",
	"Die",
})

for _, p in pairs(Apostle.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end

function Apostle.new(room)
	local self = setmetatable({}, Apostle)

	-- meta
	self.Model = self.BaseModel:Clone()
	self.HpModule = HpModule.new(self.BaseHp, self.Resistance, self.Model)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()

	self.RigMover = RigMover.new(self.Model, self.WalkSpeed, self.Size)
	self.RigMover:Align(function()
		return self.Blackboard.Target and self.Blackboard.Target.Character.PrimaryPart.Position
	end)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	-- AI
	self.AI = AILoop.join(self, self.Behavior)
	self.Blackboard = EntityBlackboard.withTracking({})

	self.HpModule.Staggered:Connect(function() self.RigMover:Stop() end)
	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Apostle:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(_G.time(spawnDelay), function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AI:Start()
	end)
end

function Apostle:GetAttackDelay(): number
	return INITIAL_ATK_DELAY + (FINAL_ATK_DELAY - INITIAL_ATK_DELAY) * (1 - self.HpModule:Percentage())
end

function Apostle:Cross(): number
	self.Sink["Cross"]:FireAllClients(20.0, 10, self.Rng:NextInteger(0, 1) * math.rad(45), 1.0)
	task.wait(_G.time(self:GetAttackDelay() + 1.0))
	return 1
end

function Apostle:Stream(): number
	self.Sink["Stream"]:FireAllClients(16.0, 24.0, 0.1, 1.0, self:GetAttackDelay())
	task.wait(_G.time(self:GetAttackDelay() + 1.0))
	return 1
end

function Apostle:Teleport(): number
	local target = self.Room:RandomPos(3.0)
	self.Sink["Teleport"]:FireAllClients(target, 1.0)
	task.wait(_G.time(1.0))
	self.Model:MoveTo(target)
	task.wait(_G.time(self:GetAttackDelay()))
	return 1
end

function Apostle:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function Apostle:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return Apostle