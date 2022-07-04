--!strict

-- NOTE: grenades are server-sided. just be glad that everything is on clietn already.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local CharControl = require(ServerScriptService.Loadout.CharControl)
local HpModule = require(ServerScriptService.AI.HpModule)
local Pathing = require(ServerScriptService.AI.Pathing)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)
local VecTools = require(ReplicatedStorage.Util.VecTools)

local PATH_COMPUTE_COOLDOWN = 0.5
local WALKSPEED = 4.0

local GRENADE_DELAY = 0.5
local GRENADE_LIFETIME = 3.0
local GRENADE_COOLDOWN = 3.0
local GRENADE_INACCURACY = math.rad(15)

local Grenadier = {}
Grenadier.__index = Grenadier
Grenadier.Name = "Grenadier"
Grenadier.BestiaryIndex = 3
Grenadier.BaseHp = 100
Grenadier.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
Grenadier.FlavorText = [[

]]

Grenadier.BaseModel = ServerStorage.Enemies.Grenadier
Grenadier.PistolModel = ServerStorage.Accessories.Pistol
Grenadier.GrenadeModel = (function()
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1.5,1.5,1.5)
	part.BrickColor = BrickColor.new("Electric blue")
	PhysicsService:SetPartCollisionGroup(part, "NPCProjectile")
	return part
end)()
Grenadier.MovementParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "NPC"
	return params
end)()
Grenadier.SinkService = Sink:CreateService("Grenadier", {
	"Spawn",
	"Run",
	"Grenade",
	"GrenadeHit",
	"Detonate",
	"TakeDamage",
	"Die",
})
for _, p in pairs(Grenadier.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
	end
end

function Grenadier.new(room)
	local self = setmetatable({}, Grenadier)

	-- meta
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Parent = ReplicatedStorage
	self.Pistol = self.PistolModel:Clone()
	CharControl.addCustomAccessory(self.Model, self.Pistol)
	self.Size = self.Model:GetExtentsSize()

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed)
	self.PPath = Pathing:CreatePath(4.0, self.Size.Y)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(plr: Player, dmg: number)
		self.HpModule:TakeUserDamage(dmg, plr)
	end)

	self.Sink["GrenadeHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId]:TakeDamage(20)
	end)

	self.Sink["Detonate"]:Connect(function(plr: Player, grenade: Part, radius: number)
		self.Sink["Detonate"]:FireAllClientsExcept(plr, grenade, radius)
	end)

	-- AI
	self.Behavior = BHTCreator:Create(self.BaseModel.Grenadier)
	self.AILoop = nil
	self.Blackboard = {
		Target = nil,
		TargetDistance = nil,
		CanGrenade = true,
		InPreferredRange = true,
	}

	self.FollowTarget = AILoop.QuickStepped:Connect(function()
		if self.Blackboard.Target then self.RigMover:LookAt(self.Blackboard.Target.Character.PrimaryPart.Position) end
	end)

	self.RigMover.MoveEnded:Connect(function()
		self.Sink["Run"]:FireAllClients(false)
	end)

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Grenadier:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(_G.time(spawnDelay), function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Grenadier:Track()
	local plr, dist = Pathing.closestPlayer(self.Model.PrimaryPart.Position, true)
	self.Blackboard.Target = plr
	self.Blackboard.TargetDistance = dist
	return if self.Blackboard.Target then 1 else 2
end

function Grenadier:MoveTo(pos: Vector3)
	self.Sink["Run"]:FireAllClients(true)
	self.RigMover:MoveTo(pos)
end

function Grenadier:LookAt(pos: Vector3)
	self.RigMover:LookAt(pos)
end

function Grenadier:Path()
	local target = Pathing.closestPlayer(self.Model.PrimaryPart.Position, false)
	if not target then return end
	if not Pathing:Compute(self.PPath, self.RigMover:Downcast().Position+self.Model.PrimaryPart.CFrame.LookVector, target.Character.PrimaryPart.Position) then
		self.RigMover:Unstick(3.0)
		return 2
	end

	self.Blackboard.CanComputePath = false
	task.delay(_G.time(PATH_COMPUTE_COOLDOWN), function()
		self.Blackboard.CanComputePath = true
	end)

	local waypoints = self.PPath:GetWaypoints()
	self.RigMover:FollowPath(waypoints)
	return 1
end

function Grenadier:Grenade()
	local grenade = self.GrenadeModel:Clone()
	grenade.CFrame = self.Pistol.Muzzle.CFrame
	grenade.Parent = ReplicatedStorage
	self.Sink["Grenade"]:FireAllClients(grenade, GRENADE_LIFETIME, GRENADE_DELAY)

	task.wait(GRENADE_DELAY)

	local force = Instance.new("VectorForce", grenade)
	force.Attachment0 = Instance.new("Attachment", grenade)
	force.RelativeTo = Enum.ActuatorRelativeTo.World

	-- takes some tuning
	local F, DT = 100, 0.1
	force.Force = self.Pistol.Muzzle.CFrame:VectorToWorldSpace(
		VecTools.rotate(Vector3.new(0, F, 0), self.Rng:NextNumber(-GRENADE_INACCURACY, GRENADE_INACCURACY), -Vector3.xAxis)
	)

	grenade.Parent = workspace
	grenade:SetNetworkOwner(nil)
	Debris:AddItem(force, DT)
	-- everything should detonate on the client first
	-- just adding an extra second before it dies on the server
	Debris:AddItem(grenade, GRENADE_LIFETIME+1.0)

	self.Blackboard.CanGrenade = false
	task.delay(_G.time(GRENADE_COOLDOWN), function() self.Blackboard.CanGrenade = true end)
	return 1
end

function Grenadier:Die()
	self.Sink["Die"]:FireAllClients()
	self:Destroy()
end

function Grenadier:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	self.FollowTarget:Disconnect()
	self.Sink:Destroy()
	self.RigMover:Destroy()
	self.Model:Destroy()
end

return Grenadier