--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local CharControl = require(ServerScriptService.Loadout.CharControl)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 8.0

local BURST_SPEED = 20.0
local BURST_FIRERATE = 0.1
local BURST_COUNT = 3
local BURST_DELAY = 0.2
local BURST_INACCURACY = math.rad(10.0)

local Merc = {}
Merc.__index = Merc
Merc.Name = "Merc"
Merc.BestiaryIndex = 20
Merc.BaseHp = 60
Merc.PreferredRange = 16.0
Merc.Resistances = {
	Ballistic = .4,
	Energy = .4,
	Chemical = 0,
	Fire = 0,
}
Merc.FlavorText = [[
Standard infantry of The Final Restitution.

The Final Restitution are composed of the only people in the world who know of the CCNT's existence outside of CCNT faculty. Backed by malignant governments and sociopathic to a fault; they will get their hands on any piece of technology they can while leaving no survivors.
]]

Merc.BaseModel = ServerStorage.Enemies.Merc
Merc.PistolModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Merc.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Merc.SinkService = Sink:CreateService("Merc", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Burst",
	"BurstHit",
	"Stagger",
	"Die",
})

function Merc.new(room)
	local self = setmetatable({}, Merc)

	-- meta
	self.Model = self.BaseModel:Clone()
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances, self.Model)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Pistol = self.PistolModel:Clone()
	CharControl.addCustomAccessory(self.Model, self.Pistol)
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed, self.Size)

	self.RigMover:Align(function()
		return self.Blackboard.Target and self.Blackboard.Target.Character.PrimaryPart.Position
	end)

	self.RigMover.MoveBegan:Connect(function()
		self.Sink["Run"]:FireAllClients(true)
	end)

	self.RigMover.MoveEnded:Connect(function()
		if self.Blackboard.Seeking then return end
		self.Sink["Run"]:FireAllClients(false)
	end)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)

	self.Sink["TakeDamage"]:Connect(function(plr: Player, dmg: any, hit: Vector3)
		self.HpModule:TakeUserDamage(plr, dmg, hit)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(self.Model.Merc)
	self.AI = AILoop.join(self, self.Behavior)
	self.Blackboard = EntityBlackboard.withPathing({
		CanBurst = true,
	})

	self.HpModule.Status.Staggered.Began:Connect(function()
		self.RigMover:Stop()
		self.Sink["Stagger"]:FireAllClients(true)
	end)

	self.HpModule.Status.Staggered.Ended:Connect(function()
		self.Sink["Stagger"]:FireAllClients(false)
	end)

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Merc:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AI:Start()
	end)
end

function Merc:Burst(): number
	self.Sink["Burst"]:FireAllClients(
		self.Blackboard.Target,
		BURST_SPEED,
		BURST_FIRERATE,
		self.Rng:NextNumber(-BURST_INACCURACY, BURST_INACCURACY),
		BURST_COUNT,
		BURST_DELAY
	)
	self.Blackboard:StartCooldown("CanBurst", 1.0 + self.Rng:NextNumber()/2)
	return 1
end

function Merc:Die()
	self.Sink["Die"]:FireAllClients()
	self.RigMover:Stop()
	self.RigMover:Unalign()
	self.AI:Disconnect()
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
		end
	end
	task.wait(_G.time(3.0))
	self.RigMover:Destroy()
	self.Model:Destroy()
end

function Merc:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return Merc