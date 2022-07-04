--!strict
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 3.0

local Revenant = {}
Revenant.__index = Revenant
Revenant.Name = "Revenant"
Revenant.IsBoss = true
Revenant.BaseHp = 1000
Revenant.BestiaryIndex = 0
Revenant.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
Revenant.FlavorText = [[
This mutated former security member gorges on the corpses of its victims. Thankfully, he's relatively stupid.
]]

Revenant.PreferredRange = 10.0
Revenant.BaseModel = ServerStorage.Enemies.Revenant
for _, p in pairs(Revenant.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Revenant.SinkService = Sink:CreateService("Revenant", {
	"Spawn",
	"TakeDamage",
	"Run",
	"MoveField",
	"EndField",
	"BigField",
	"Trap",
	"Row",
	"Scatter",
	"Stage2",
	"Finale",
	"Die",
})

function Revenant.new(room)
	local self = setmetatable({}, Revenant)

	-- meta
	self.Model = self.BaseModel:Clone()
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed, self.Size)

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
	self.AILoop = nil
	self.Behavior = BHTCreator:Create(Revenant.BaseModel.Revenant)
	self.Blackboard = EntityBlackboard.new({
		Target = nil,
		TargetDistance = math.huge,
		InPreferredRange = false,
		Seeking = false,
		CanComputePath = true,
		CanScatter = true,
		Stage2 = false,
	})

	self.RigMover:Align(function()
		return self.Blackboard.Target and self.Blackboard.Target.Character.PrimaryPart.Position
	end)

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Revenant:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Revenant:MoveTo(target: Vector3)
	self.Sink["MoveField"]:FireAllClients(4.0, 0.2, self.Rng:NextNumber())
	self.RigMover:MoveTo(target, 10.0)
	self.RigMover.MoveEnded:Wait()
	self.Sink["EndField"]:FireAllClients()
end

function Revenant:MoveField(): number
	local target = self.Room:RandomPos(4.0)
	self:MoveTo(target)
	return 1
end

function Revenant:BigField(): number
	self.Sink["BigField"]:FireAllClients(4.0, 16.0, 0.75)
	task.wait(_G.time(0.75*4+1.0))
	return 1
end

function Revenant:Trap(): number
	self.Sink["Trap"]:FireAllClients(game.Players.Speedmask, 8.0, 10.0, 4.0)
	task.wait(_G.time(1.0))
	return 1
end

function Revenant:Row(): number
	self.Sink["Row"]:FireAllClients(
		game.Players.Speedmask,
		8,
		4.0,
		15.0,
		self.Rng:NextInteger(1, 2)
	)
	task.wait(_G.time(1.0))
	return 1
end

function Revenant:Scatter(): number
	local points = {}
	for _=1, 30 do
		points[#points+1] = {
			Position = self.Room:RandomPos(0.5, 3.0),
			Direction = self.Room.CFrame:VectorToWorldSpace(
				Vector3.new(
					if self.Rng:NextInteger(0, 1) == 0 then -1 else 1,
					0,
					if self.Rng:NextInteger(0, 1) == 0 then -1 else 1
				)
			),
		}
	end
	self.Sink["Scatter"]:FireAllClients(points, 5.0, 2.0)
	task.wait(_G.time(2.0))
	self.Blackboard:StartCooldown("CanScatter", 8.0)
	return 1
end

function Revenant:Die()
	if self.AILoop then self.AILoop:Disconnect() end
	self:MoveTo(self.Room:PointFromUDim2(UDim2.fromScale(.5, .5)))
	RunService.Heartbeat:Wait()
	self.Sink["Die"]:FireAllClients()
	task.wait(_G.time(5.0))
	self.RigMover:Destroy()
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
		end
	end
	task.wait(_G.time(3.0))
	self.Model:Destroy()
end

function Revenant:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return Revenant