--!strict
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local CharControl = require(ServerScriptService.Loadout.CharControl)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local Pathing = require(AI.Pathing)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 6.0

local SNIPE_CHARGE = 1.0
local SNIPE_DELAY = 0.2
local SNIPE_COOLDOWN = 3.0

local Marksman = {}
Marksman.__index = Marksman
Marksman.Name = "Marksman"
Marksman.BestiaryIndex = 4
Marksman.BaseHp = 100
Marksman.PreferredRange = 1e6
Marksman.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
Marksman.FlavorText = [[
Basic enemy with laser rifle.

The giant laser beams that appeared before shooting weren't really a great tactical decision.
]]

Marksman.BaseModel = ServerStorage.Enemies.Marksman
Marksman.PistolModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Marksman.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Marksman.SinkService = Sink:CreateService("Marksman", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Snipe",
	"SnipeHit",
	"Die",
})

function Marksman.new(room)
	local self = setmetatable({}, Marksman)

	-- meta
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances, self.Size)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Pistol = self.PistolModel:Clone()
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed, self.Size)

	self.RigMover.MoveEnded:Connect(function()
		self.Sink["Run"]:FireAllClients(false)
	end)

	self.RigMover:Align(function()
		return self.Blackboard.Target and not self.Blackboard.TargetLocked and self.Blackboard.Target.Character.PrimaryPart.Position
	end)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(self.Model.Marksman)
	self.AI = AILoop.join(self, self.Behavior)
	self.Blackboard = EntityBlackboard.withPathing({
		CanSnipe = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Marksman:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AI:Start()
	end)
end

function Marksman:Snipe(): number
	self.Sink["Snipe"]:FireAllClients(
		self.Blackboard.Target,
		SNIPE_CHARGE,
		SNIPE_DELAY
	)

	task.wait(_G.time(SNIPE_CHARGE))
	self.Blackboard.TargetLocked = true
	task.wait(_G.time(SNIPE_DELAY))
	self.Blackboard.TargetLocked = false

	self.Blackboard:StartCooldown("CanSnipe", SNIPE_COOLDOWN)
	return 1
end

function Marksman:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function Marksman:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return Marksman