local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local HpModule = require(AI.HpModule)
local Pathing = require(AI.Pathing)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 2.0
local RADIAL_DMG = 10
local RADIAL_MIN_V_S = 1.0
local RADIAL_MAX_V_S = 4.0
local RADIAL_COUNT = 10
local RADIAL_COOLDOWN = 5.0
local RADIAL_RATE = 0.5
local RADIAL_BURSTS = 3

local Entropy = {}
Entropy.__index = Entropy
Entropy.Name = "Entropy"
Entropy.Resistances = {
	Ballistic = .2,
	Energy = .8,
	Chemical = .8,
	Fire = .8,
}
Entropy.FlavorText = [[
A tough organism that releases clusters of spores from behind a regenerating shield. Protip: the shield has 100% ballistic resistance.

This thing is literally a cylinder with bulbs on it. It's a little known fact that this is peak evolution.
]]

Entropy.BaseModel = ServerStorage.Enemies.Entropy
Entropy.PistolModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Entropy.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Entropy.Behavior = BHTCreator:Create(Entropy.BaseModel.Entropy)
Entropy.SinkService = Sink:CreateService("Entropy", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Radial",
	"RadialHit",
	"Die",
})

function Entropy.new(room: any)
	local self = setmetatable({}, Entropy)

	-- meta
	self.HpModule = HpModule.new(500)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)
	self.PPath = Pathing:CreatePath(4.0, self.Size.Y)

	self.RigMover.MoveEnded:Connect(function()
		self.Sink["Run"]:FireAllClients(false)
	end)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(plr: Player, dmg: number)
		self.HpModule:TakeUserDamage(dmg, plr)
	end)

	self.HpModule.Died:Connect(function() self:Die() end)

	self.Sink["RadialHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId].HpModule:TakeDamage(RADIAL_DMG)
	end)

	-- AI
	self.AILoop = nil
	self.Blackboard = {
		CanEmit = true,
	}

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Entropy:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(_G.time(spawnDelay), function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Entropy:Track()
	return if Pathing.closestPlayer(self.Model.PrimaryPart.Position) ~= nil then 1 else 2
end

function Entropy:Radial()
	local projectiles = table.create(RADIAL_BURSTS)
	for i=1,RADIAL_BURSTS do
		projectiles[i] = table.create(RADIAL_COUNT)
		for j=1,RADIAL_COUNT do
			projectiles[i][j] = {
				direction = self.Rng:NextUnitVector() * Vector3.new(1, 0, 1),
				speed = self.Rng:NextNumber(RADIAL_MIN_V_S, RADIAL_MAX_V_S),
			}
		end
	end
	self.Sink["Radial"]:FireAllClients(projectiles, RADIAL_RATE)
	task.wait(RADIAL_RATE * RADIAL_BURSTS)
	self.Blackboard.CanEmit = false
	task.delay(_G.time(RADIAL_COOLDOWN), function()
		self.Blackboard.CanEmit = true
	end)
	return 1
end

return Entropy