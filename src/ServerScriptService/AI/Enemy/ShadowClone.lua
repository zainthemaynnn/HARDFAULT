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
local Pathing = require(AI.Pathing)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 3.0

local SPREAD_SPEED = 10.0
local SPREAD_COUNT = 5
local SPREAD_SPREAD = math.rad(30.0)
local SPREAD_DELAY = 0.2
local SPREAD_DMG = 10
local SPREAD_COOLDOWN = 3.0

local ShadowClone = {}
ShadowClone.__index = ShadowClone
ShadowClone.Name = "ShadowClone"
ShadowClone.BaseHp = 100
ShadowClone.BestiaryIndex = 2
ShadowClone.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
ShadowClone.FlavorText = [[
Aggressive robot wielding an electric Orbgun.

"CHK-CHK! BOOOOOM! YEAHHHHHHHHHHHHHHHH!"
]]

ShadowClone.PreferredRange = 10.0
ShadowClone.BaseModel = ServerStorage.Enemies.ShadowClone
ShadowClone.PistolModel = ServerStorage.Accessories.Pistol
for _, p in pairs(ShadowClone.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
ShadowClone.SinkService = Sink:CreateService("ShadowClone", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Spread",
	"SpreadHit",
	"Die",
})

function ShadowClone.new(room)
	local self = setmetatable({}, ShadowClone)

	-- meta
	self.HpModule = HpModule.new(self.BaseHp)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
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

	self.RigMover.MoveEnded:Connect(function()
		self.Sink["Run"]:FireAllClients(false)
	end)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(plr: Player, dmg: number)
		self.HpModule:TakeUserDamage(dmg, plr)
	end)

	self.Sink["SpreadHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId].HpModule:TakeDamage(SPREAD_DMG)
	end)

	-- AI
	self.AILoop = nil
	self.Behavior = BHTCreator:Create(ShadowClone.BaseModel.ShadowClone)
	self.Blackboard = EntityBlackboard.new({
		Target = nil,
		TargetDistance = math.huge,
		InPreferredRange = false,
		Seeking = false,
		CanSpread = true,
		CanComputePath = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function ShadowClone:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(_G.time(spawnDelay), function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function ShadowClone:MoveTo(pos: Vector3)
	self.Sink["Run"]:FireAllClients(true)
	self.RigMover:MoveTo(pos)
end

function ShadowClone:LookAt(pos: Vector3)
	self.RigMover:LookAt(pos)
end

function ShadowClone:Spread(): number
	self:LookAt(self.Blackboard.Target.Character.PrimaryPart.Position)

	self.Sink["Spread"]:FireAllClients(
		self.Blackboard.Target,
		SPREAD_SPEED,
		SPREAD_COUNT,
		SPREAD_SPREAD,
		SPREAD_DELAY
	)

	task.wait(SPREAD_DELAY)

	self.Blackboard:StartCooldown("CanSpread", SPREAD_COOLDOWN)
	return 1
end

function ShadowClone:Die()
	self.Sink["Die"]:FireAllClients()
	if self.AILoop then self.AILoop:Disconnect() end
	self.RigMover:Destroy()
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
		end
	end
	task.wait(1.0)
	self.Model:Destroy()
end

function ShadowClone:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return ShadowClone