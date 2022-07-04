local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local CharControl = require(ServerScriptService.Loadout.CharControl)
local HpModule = require(AI.HpModule)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 6.0
local BOMB_COOLDOWN = 2.0
local BOMB_LIFETIME = BOMB_COOLDOWN * 5
local BOMB_RADIUS = 2.0

local ADrop = {}
ADrop.__index = ADrop
ADrop.Name = "ADrop"
ADrop.BaseHp = 100
ADrop.Resistances = {
	Ballistic = .5,
	Energy = .5,
	Chemical = .2,
	Fire = .2,
}
ADrop.FlavorText = [[
Why are these guys so cute?
]]

ADrop.BaseModel = ServerStorage.Enemies.ADrop
for _, p in pairs(ADrop.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
ADrop.MovementParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "Invulnerable"
	return params
end)()
ADrop.SinkService = Sink:CreateService("ADrop", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Bomb",
	"BombHit",
	"Die",
})

function ADrop.new(room, a0: number)
	local self = setmetatable({}, ADrop)

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
	self.InitialAngle = a0

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	self.Sink["BombHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId].HpModule:TakeDamage(50)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(ADrop.BaseModel.ADrop)
	self.AILoop = nil
	self.Blackboard = {
		IsMoving = false,
		BombReady = true,
	}

	self.RigMover.MoveEnded:Connect(function()
		self.Blackboard.IsMoving = false,
		self.Sink["Run"]:FireAllClients(false)
	end)

	return self
end

function ADrop:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self:LookAt(pos + self.Room.CFrame:PointToWorldSpace(Vector3.new(-math.cos(self.InitialAngle), 0, math.sin(self.InitialAngle))))
		RunService.Stepped:Wait()
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function ADrop:MoveTo(pos: Vector3)
	self.Sink["Run"]:FireAllClients(true)
	self.Blackboard.IsMoving = true
	self.RigMover:MoveTo(pos)
end

function ADrop:LookAt(pos: Vector3)
	self.RigMover:LookAt(pos)
end

function ADrop:Turn()
	local cf = self.Model.PrimaryPart.CFrame
	local pos0, dir0 = cf.Position, cf.LookVector
	local res0 = workspace:Raycast(pos0, dir0 * 100, self.MovementParams)
	if not res0 then return false end
	local dir1 = dir0 - 2 * dir0:Dot(res0.Normal) * res0.Normal
	local res1 = workspace:Raycast(pos0, dir1 * 100, self.MovementParams)
	if not res1 then return false end
	local pos1 = res1.Position - dir1 * self.Size.X/2
	self:LookAt(pos1)
	self:MoveTo(pos1)
	return true
end

function ADrop:DeployBomb()
	self.Sink["Bomb"]:FireAllClients(BOMB_LIFETIME, BOMB_RADIUS)
	self.Blackboard.BombReady = false
	task.delay(BOMB_COOLDOWN, function()
		self.Blackboard.BombReady = true
	end)
	return true
end

function ADrop:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function ADrop:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
	self.Targetting:Disconnect()
end

return ADrop