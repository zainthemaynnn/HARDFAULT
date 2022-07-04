--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local HpModule = require(AI.HpModule)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 4.0

local SPRAY_SPEED = 16.0
local SPRAY_DURATION = 3.0
local SPRAY_SPREAD = math.rad(45.0)
local SPRAY_RATE = 0.1
local SPRAY_COOLDOWN = 3.0

local Assault = {}
Assault.__index = Assault
Assault.Name = "Assault"
Assault.BaseHp = 60
Assault.BestiaryIndex = 5
Assault.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
Assault.FlavorText = [[
Aggressive robot wielding an electric Orbgun.

"CHK-CHK! BOOOOOM! YEAHHHHHHHHHHHHHHHH!"
]]

Assault.PreferredRange = 16.0
Assault.BaseModel = ServerStorage.Enemies.Assault
Assault.PistolModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Assault.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Assault.SinkService = Sink:CreateService("Assault", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Spray",
	"Die",
})

function Assault.new(room)
	local self = setmetatable({}, Assault)

	-- meta
	self.Model = self.BaseModel:Clone()
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances, self.Model)
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Pistol = self.PistolModel:Clone()
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, WALKSPEED, self.Size)

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

	-- AI
	self.Behavior = BHTCreator:Create(Assault.BaseModel.Assault)
	self.AI = AILoop.join(self, self.Behavior)
	self.Blackboard = AILoop.Blackboard.withPathing({
		CanSpray = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Assault:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = self.AI:Start()
	end)
end

function Assault:Spray(): number
	self.Sink["Spray"]:FireAllClients(
		self.Blackboard.Target,
		SPRAY_SPEED,
		SPRAY_DURATION,
		SPRAY_RATE,
		SPRAY_SPREAD,
		os.time()
	)

	self.Blackboard:StartCooldown("CanSpray", SPRAY_DURATION + SPRAY_COOLDOWN)
	return 1
end

function Assault:Die()
	self.Sink["Die"]:FireAllClients()
	self.RigMover:Destroy()
	self.AI:Disconnect()
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
		end
	end
	task.wait(_G.time(3.0))
	self.Model:Destroy()
end

function Assault:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return Assault