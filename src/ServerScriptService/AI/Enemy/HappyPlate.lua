--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local HTTP = game:GetService("HttpService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local RigMover = require(AI.RigMover)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local Sink = require(ReplicatedStorage.Sink)

local DETECTION_RADIUS = 60.0
local WALKSPEED = 2.0
local SPAWN_DELAY = 3.0
local EXPLODE_DELAY = .5
local EXPLODE_DURATION = 0
local EXPLODE_FADE = 0.5
local EXPLODE_RADIUS = 4.0

local SWAN_SONG = EXPLODE_DELAY + EXPLODE_DURATION + 5.0

local HappyPlate = {}
HappyPlate.__index = HappyPlate
HappyPlate.Name = "Happy Plate"
HappyPlate.Resistances = {
	Ballistic = -.4,
	Energy = .2,
	Chemical = 0,
	Fire = 0,
}
HappyPlate.FlavorText = [[
Go on, give it a hug.
]]

HappyPlate.BaseModel = ServerStorage.Enemies.HappyPlate
for _, p in pairs(HappyPlate.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
HappyPlate.Behavior = BHTCreator:Create(HappyPlate.BaseModel.HappyPlate)
HappyPlate.ExplodeParams = (function()
	local params = OverlapParams.new()
	params.CollisionGroup = "NPCSensProjectile"
	return params
end)()
HappyPlate.SinkService = Sink:CreateService("HappyPlate", {
	"Spawn",
	"TakeDamage",
	"Explode",
	"ExplodeHit",
})

function HappyPlate.new(room)
	local self = setmetatable({}, HappyPlate)

	-- meta
	self.HP = 100
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)

	-- combat
	self.Sink = Sink:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	-- AI
	self.Blackboard = {
		Target = nil,
		TargetDistance = nil,
		Exploding = false,
	}
	self.AILoop = nil

	self.Sink["Explode"]:Connect(function() self:Explode() end)
	self.Sink["ExplodeHit"]:Connect(function(p) print(p) end)

	return self
end

function HappyPlate:Spawn(pos: Vector3)
	self.Sink["Spawn"]:FireAllClients(SPAWN_DELAY)
	task.wait(SPAWN_DELAY)
	self.Model.Parent = workspace
	self.Model:SetPrimaryPartCFrame(cf)
	self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
end

function HappyPlate:TakeDamage(amount: number, dealer: Player?)
	self.HP -= amount
	if self.HP <= 0 then
		self:Die()
	end
end

function HappyPlate:Track()
	local player = nil
	local dist = DETECTION_RADIUS
	for _, p in pairs(Players:GetPlayers()) do
		local char = p.Character
		if not char then continue end
		local pdist = (self.RigMover:ToLevel(char.PrimaryPart.Position) - self.Model.PrimaryPart.Position).Magnitude
		if pdist < dist and pdist < DETECTION_RADIUS then
			dist = pdist
			player = p
		end
	end

	self.Blackboard.Target = player
	self.Blackboard.TargetDistance = dist
	return if self.Blackboard.Target then true else false
end

function HappyPlate:MoveTo(pos: Vector3)
	self.RigMover:MoveTo(pos)
end

function HappyPlate:Stop()
	self.RigMover:Stop()
end

function HappyPlate:Explode()
	if self.Blackboard.Exploding then return end
	self.Blackboard.Exploding = true
	self.RigMover:Stop()
	task.wait(EXPLODE_DELAY)
	self.Sink["Explode"]:FireAllClients(EXPLODE_RADIUS, EXPLODE_DURATION, EXPLODE_FADE)
	task.wait(EXPLODE_DURATION)
	self:Die()
end

function HappyPlate:Die()
	self:Destroy()
end

function HappyPlate:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.RigMover:Destroy()
	self.Model:Destroy()
	task.delay(_G.time(SWAN_SONG), function() self.Sink:Destroy() end)
end

return HappyPlate