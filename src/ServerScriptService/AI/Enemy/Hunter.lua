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

local SPREAD_SPEED = 16.0
local SPREAD_COUNT = 5
local SPREAD_SPREAD = math.rad(22.5)
local SPREAD_DELAY = 0.2
local SPREAD_DMG = 10
local SPREAD_COOLDOWN = 3.0

local Hunter = {}
Hunter.__index = Hunter
Hunter.Name = "Hunter"
Hunter.BaseHp = 60
Hunter.BestiaryIndex = 2
Hunter.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
Hunter.FlavorText = [[
Aggressive robot wielding an electric shotgun.

"CHK-CHK! BOOOOOM! YEAHHHHHHHHHHHHHHHH!"
]]

Hunter.PreferredRange = 10.0
Hunter.BaseModel = ServerStorage.Enemies.Hunter
Hunter.PistolModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Hunter.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Hunter.SinkService = Sink:CreateService("Hunter", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Spread",
	"SpreadHit",
	"Die",
})

function Hunter.new(room)
	local self = setmetatable({}, Hunter)

	-- meta
	self.Model = self.BaseModel:Clone()
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances)
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
		self.Sink["Run"]:FireAllClients(false)
	end)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	self.Sink["SpreadHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId].HpModule:TakeDamage(SPREAD_DMG)
	end)

	-- AI
	self.AILoop = nil
	self.Behavior = BHTCreator:Create(Hunter.BaseModel.Hunter)
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

function Hunter:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Hunter:Spread(): number
	self.RigMover:LookAt(self.Blackboard.Target.Character.PrimaryPart.Position)

	self.Sink["Spread"]:FireAllClients(
		self.Blackboard.Target,
		SPREAD_SPEED,
		SPREAD_COUNT,
		SPREAD_SPREAD,
		SPREAD_DELAY
	)

	task.wait(_G.time(SPREAD_DELAY))

	self.Blackboard:StartCooldown("CanSpread", SPREAD_COOLDOWN)
	return 1
end

function Hunter:Die()
	self.Sink["Die"]:FireAllClients()
	self.RigMover:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
		end
	end
	task.wait(_G.time(3.0))
	self.Model:Destroy()
end

function Hunter:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return Hunter