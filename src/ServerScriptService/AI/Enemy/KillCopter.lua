--!strict

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local HTTP = game:GetService("HttpService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local CIRCLE_RADIUS = 5.0
local WALKSPEED = 8.0

local KillCopter = {}
KillCopter.__index = KillCopter
KillCopter.Name = "KillCopter"
KillCopter.BaseHp = 50
KillCopter.BestiaryIndex = 6
KillCopter.Resistances = {
	Ballistic = 0,
	Energy = .2,
	Chemical = 0,
	Fire = .2,
}
KillCopter.FlavorText = [[
Evasive sniping drone.

Why is it sad? Actually, it's programmed to have debilitating depression until it kills you.
]]

KillCopter.BaseModel = ServerStorage.Enemies.KillCopter
KillCopter.SinkService = Sink:CreateService("KillCopter", {
	"Spawn",
	"TakeDamage",
	"Shoot",
	"Die",
})
for _, p in pairs(KillCopter.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end

function KillCopter.new(room)
	local self = setmetatable({}, KillCopter)

	-- meta
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()
	self.Radius = CIRCLE_RADIUS

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed, self.Size)
	self.MovementParams = (function()
		local params = RaycastParams.new()
		params.CollisionGroup = "NPC"
		return params
	end)()
	self.RigMover:Align(function() return self.Blackboard.Target and self.Blackboard.Target.Character.PrimaryPart.Position end)

	self.RootPos = nil
	self.RotateConnection = nil

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(self.Model.KillCopter)
	self.AILoop = nil
	self.Blackboard = EntityBlackboard.new({
		Target = nil,
		TargetDistance = nil,
		CanShoot = true,
		Seeking = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function KillCopter:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self:Circle()
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function KillCopter:Circle()
	self.RootPos = self.Model.PrimaryPart.Position
	local t = 0
	self.RotateConnection = RunService.Heartbeat:Connect(function(dt)
		t += dt
		local v, r = self.WalkSpeed, self.Radius
		local a = t*(v/r)
		self.RigMover:MoveTo(self.RootPos + Vector3.new(math.cos(a)*r, 0, math.sin(a)*r))
	end)
end

function KillCopter:MoveTo(pos: Vector3)
	if self.RotateConnection then self.RotateConnection:Disconnect() end
	self.RigMover:MoveTo(pos)
	self.MoveEnded:Connect(function() self:Circle() end)
end

function KillCopter:Shoot(): number
	self.Sink["Shoot"]:FireAllClients(self.Blackboard.Target, 10.0, 1.0)
	self.Blackboard:StartCooldown("CanShoot", 1.0)
	return 1
end

function KillCopter:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function KillCopter:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	if self.RotateConnection then self.RotateConnection:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return KillCopter