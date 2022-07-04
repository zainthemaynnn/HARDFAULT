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
local PlayerData = require(ServerScriptService.Game.PlayerData)
local Projectiles = require(ReplicatedStorage.Projectiles)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 6.0

local CROAK_VELOCITY = 10.0
local CROAK_SPREAD = math.rad(45.0)
local CROAK_DIST = NumberRange.new(1.0, 15.0)
local CROAK_N = 30
local CROAK_STANDBY = NumberRange.new(3.0, 4.0)
local CROAK_DELAY = 1.0
local CROAK_DMG = 10

local ATK_RATE = 1.0

local Frog = {}
Frog.__index = Frog
Frog.Name = "Frog"
Frog.BestiaryIndex = 1
Frog.BaseHp = 100
Frog.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
Frog.FlavorText = [[
rawr
]]

Frog.BaseModel = ServerStorage.Enemies.Frog
for _, p in pairs(Frog.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Frog.SinkService = Sink:CreateService("Frog", {
	"Spawn",
	"TakeDamage",
	"Croak",
	"CroakHit",
	"Die",
})

function Frog.new(room)
	local self = setmetatable({}, Frog)

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

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(plr: Player, dmg: number)
		self.HpModule:TakeUserDamage(dmg, plr)
	end)

	self.Sink["CroakHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId].HpModule:TakeDamage(CROAK_DMG)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(self.Model.Frog)
	self.AILoop = nil
	self.Blackboard = EntityBlackboard.new({
		CanCroak = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Frog:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(_G.time(spawnDelay), function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Frog:Croak()
	local directions = {}
	local standby = {}
	for _=1,CROAK_N do
		local dir = Projectiles.VecTools.rotate(
			-Vector3.zAxis,
			self.Rng:NextNumber(-CROAK_SPREAD, CROAK_SPREAD)
		)
		local dist = self.Rng:NextNumber(CROAK_DIST.Min, CROAK_DIST.Max)
		directions[#directions+1] = dir * dist
		standby[#standby+1] = self.Rng:NextNumber(CROAK_STANDBY.Min, CROAK_STANDBY.Max)
	end

	self.Sink["Croak"]:FireAllClients(
		CROAK_VELOCITY,
		CROAK_DIST.Max,
		directions,
		standby,
		CROAK_DELAY
	)
	self.Blackboard:StartCooldown("CanCroak", CROAK_DELAY+5.0)
	return true
end

function Frog:Die()
	self.Sink["Die"]:FireAllClients()
	if self.AILoop then self.AILoop:Disconnect() end
	self.RigMover:Destroy()
	self.Model:Destroy()
end

function Frog:Destroy()
	self.Sink:Destroy()
end

return Frog