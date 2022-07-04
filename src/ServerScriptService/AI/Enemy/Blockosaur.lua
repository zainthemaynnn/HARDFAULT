local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 6.0

local BURST_SPEED = 16.0
local BURST_SEGSIZE = 25
local BURST_DELAY = 0.25
local ATK_RATE = 5.0

local Blockosaur = {}
Blockosaur.__index = Blockosaur
Blockosaur.Name = "Blockosaur"
Blockosaur.BestiaryIndex = 6
Blockosaur.BaseHp = 300
Blockosaur.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
Blockosaur.FlavorText = [[
rawr
]]

Blockosaur.BaseModel = ServerStorage.Enemies.Blockosaur
for _, p in pairs(Blockosaur.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Blockosaur.SinkService = Sink:CreateService("Blockosaur", {
	"Spawn",
	"TakeDamage",
	"Burst",
	"Die",
})

function Blockosaur.new(room)
	local self = setmetatable({}, Blockosaur)

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

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(self.Model.Blockosaur)
	self.AILoop = nil
	self.Blackboard = EntityBlackboard.new({
		CanBurst = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Blockosaur:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Blockosaur:Burst(): number
	self.Sink["Burst"]:FireAllClients(
		BURST_SPEED,
		BURST_SEGSIZE,
		BURST_DELAY
	)
	self.Blackboard:StartCooldown("CanBurst", BURST_DELAY + ATK_RATE)
	return 1
end

function Blockosaur:Die()
	self.Sink["Die"]:FireAllClients()
	if self.AILoop then self.AILoop:Disconnect() end
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
		end
	end
	task.wait(_G.time(1.0))
	self.Model:Destroy()
end

function Blockosaur:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return Blockosaur