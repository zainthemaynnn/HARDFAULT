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

local DETECTION_RADIUS = 60.0
local WALKSPEED = 4.0
local STRAFE_DIST = 10.0
local STRAFE_PAD = 5.0

local REVOLVER_SPEED = 30.0
local REVOLVER_DELAY = 0.2
local REVOLVER_INACCURACY = math.rad(10.0)

local Ricochet = {}
Ricochet.__index = Ricochet
Ricochet.Name = "Ricochet"
Ricochet.BaseHp = 100
Ricochet.Resistances = {
	Ballistic = 0,
	Energy = 1,
	Chemical = 0,
	Fire = 0,
}
Ricochet.FlavorText = [[
Uses cloaking technology to fire ricocheting bullets unnoticed.

Before you call this unfair, remember that you can TELEPORT.
]]

Ricochet.BaseModel = ServerStorage.Enemies.Ricochet
Ricochet.PistolModel = ServerStorage.Accessories.Pistol
for _, p in pairs(Ricochet.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end
Ricochet.SinkService = Sink:CreateService("Ricochet", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Revolver",
	"RevolverHit",
	"Die",
})
Ricochet.MovementParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "NPC"
	return params
end)()

function Ricochet.new(room)
	local self = setmetatable({}, Ricochet)

	-- meta
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances)
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
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	self.Sink["RevolverHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId].HpModule:TakeDamage(20)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(Ricochet.BaseModel.Ricochet)
	self.AILoop = nil
	self.Blackboard = {
		Target = nil,
		TargetDistance = nil,
	}

	self.RigMover.MoveEnded:Connect(function()
		self.Sink["Run"]:FireAllClients(false)
	end)

	self.Targetting = RunService.Heartbeat:Connect(function()
		if self.Blackboard.Target then self:LookAt(self.Blackboard.Target.Character.PrimaryPart.Position) end
	end)

	return self
end

function Ricochet:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Ricochet:Track()
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

function Ricochet:MoveTo(pos: Vector3)
	self.Sink["Run"]:FireAllClients(true)
	self.RigMover:MoveTo(pos)
end

function Ricochet:Strafe()
	local pos0 = self.Model.PrimaryPart.Position
	local dir
	while true do
		local t = self.Rng:NextNumber(0, 2*math.pi)
		dir = Vector3.new(math.cos(t), 0, math.sin(t))
		if not workspace:Raycast(
			pos0,
			dir * (STRAFE_DIST + STRAFE_PAD),
			self.MovementParams
		) then break end
	end

	local dest = pos0 + dir * STRAFE_DIST
	self:MoveTo(dest)

	self.RigMover.MoveEnded:Wait()
end

function Ricochet:LookAt(pos: Vector3)
	self.RigMover:LookAt(pos)
end

function Ricochet:Shoot()
	self.Sink["Revolver"]:FireAllClients(
		self.Blackboard.Target,
		REVOLVER_SPEED,
		self.Rng:NextNumber(-REVOLVER_INACCURACY, REVOLVER_INACCURACY),
		REVOLVER_DELAY
	)
	task.wait(_G.time(REVOLVER_DELAY + 1.0))
end

function Ricochet:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function Ricochet:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
	self.Targetting:Disconnect()
end

return Ricochet