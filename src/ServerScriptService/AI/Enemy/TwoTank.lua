--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local Pathing = require(AI.Pathing)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local STOMP_SPEED = 16.0
local STOMP_COUNT = 16
local STOMP_DELAY = 1.0

local TwoTank = {}
TwoTank.__index = TwoTank
TwoTank.Name = "TwoTank"
TwoTank.BestiaryIndex = 8
TwoTank.BaseHp = 120
TwoTank.WalkSpeed = 6.0
TwoTank.Resistances = {
	Ballistic = .7,
	Energy = .4,
	Chemical = .2,
	Fire = .4,
}
TwoTank.FlavorText = [[
Highly resistant enemy that supports its teammates with constant fire.

The guy who engineered this one was a star wars fan.
]]

TwoTank.BaseModel = ServerStorage.Enemies.TwoTank
for _, p in pairs(TwoTank.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
TwoTank.SinkService = Sink:CreateService("TwoTank", {
	"Spawn",
	"TakeDamage",
	"Stomp",
	"DualStomp",
	"Die",
})

function TwoTank.new(room)
	local self = setmetatable({}, TwoTank)

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
	self.Behavior = BHTCreator:Create(self.Model.TwoTank)
	self.AILoop = nil
	self.Blackboard = EntityBlackboard.new({
		Target = false,
		TargetDistance = math.huge,
		CanStomp = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function TwoTank:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function TwoTank:Track()
	local plr, dist = Pathing.closestPlayer(self.Model.PrimaryPart.Position, true)
	if plr and not self.Blackboard.Target then
		self.RigMover:Stop()
	end
	self.Blackboard.Target = plr or false
	self.Blackboard.TargetDistance = dist
	return if self.Blackboard.Target then true else false
end

function TwoTank:Stomp(): boolean
	local turret = self.Rng:NextInteger(1, 2)
	if turret == 1 or turret == 2 then
		self.Sink["Stomp"]:FireAllClients(
			turret,
			STOMP_SPEED,
			STOMP_COUNT,
			STOMP_DELAY
		)
		self.Blackboard:StartCooldown("CanStomp", STOMP_DELAY + 0.5)
	else
		self.Sink["DualStomp"]:FireAllClients(
			STOMP_SPEED,
			STOMP_COUNT,
			STOMP_DELAY
		)
		self.Blackboard:StartCooldown("CanStomp", STOMP_DELAY + 0.5)
	end
	return true
end

function TwoTank:Die()
	self.Sink["Die"]:FireAllClients()
	if self.AILoop then self.AILoop:Disconnect() end
	self.RigMover:Destroy()
	task.wait(_G.time(2.0))
	local explosion = Instance.new("Explosion")
	explosion.Position = self.Model.PrimaryPart.Position
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.DestroyJointRadiusPercent = 0
	explosion.BlastPressure = 0
	explosion.Parent = workspace
	task.wait(_G.time(1.0))
	self.Model:Destroy()
end

function TwoTank:Destroy()
	self.Sink:Destroy()
end

return TwoTank