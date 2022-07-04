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
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 8.0

local MopNinja = {}
MopNinja.__index = MopNinja
MopNinja.Name = "Mop Ninja"
MopNinja.BaseHp = 100
MopNinja.BestiaryIndex = 5
MopNinja.Resistances = {
	Ballistic = 0,
	Energy = .4,
	Chemical = -.2,
	Fire = 0,
}
MopNinja.FlavorText = [[
This guy is scarily proficient at killing things with a mop.

Stop dirtying up the floor, bro.
]]

MopNinja.PreferredRange = 15.0
MopNinja.DoubleSlashRange = 16.0
MopNinja.SpinRange = 4.0
MopNinja.BaseModel = ServerStorage.Enemies.MopNinja
for _, p in pairs(MopNinja.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "SoftNPC")
	end
end
MopNinja.SinkService = Sink:CreateService("MopNinja", {
	"Spawn",
	"TakeDamage",
	"Run",
	"DoubleSlash",
	"DoubleSlashHit",
	"Spin",
	"SpinHit",
	"Die",
})

function MopNinja.new(room)
	local self = setmetatable({}, MopNinja)

	-- meta
	self.HpModule = HpModule.new(self.BaseHp, self.Resistances, self.Model)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model = self.BaseModel:Clone()
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Mop = self.Model.Mop
	self.Size = self.Model:GetExtentsSize()
	self.Mass = self.Model.PrimaryPart.AssemblyMass

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed, self.Size)

	self.RigMover:Align(function()
		return self.Blackboard.Target and self.Blackboard.Target.Character.PrimaryPart.Position
	end)

	self.RigMover.MoveBegan:Connect(function()
		self.Sink["Run"]:FireAllClients(true)
	end)

	self.RigMover.MoveEnded:Connect(function()
		if self.Blackboard.Seeking then return end
		self.Sink["Run"]:FireAllClients(false)
	end)

	-- combat
	self.Sink = self.SinkService:Relay(self.Model)
	self.Model.Name = self.Sink:GetGUID()

	self.Sink["TakeDamage"]:Connect(function(plr: Player, dmg: number)
		--self.RigMover:Impulse((10.0 * self.Mass)/(0.1^2) * dmg.Velocity.Unit, 0.1)
		self.HpModule:TakeUserDamage(dmg, plr)
	end)

	self.Sink["DoubleSlashHit"]:Connect(function(plr: Player)
		local pdata = PlayerData[plr.UserId]
		pdata.HpModule:TakeDamage(0)
	end)

	self.Sink["SpinHit"]:Connect(function(plr: Player)
		local pdata = PlayerData[plr.UserId]
		pdata.HpModule:TakeDamage(0)
	end)

	-- AI
	self.AILoop = nil
	self.Behavior = BHTCreator:Create(MopNinja.BaseModel.MopNinja)
	self.Blackboard = EntityBlackboard.new({
		Target = nil,
		TargetDistance = math.huge,
		InPreferredRange = false,
		Seeking = false,
		CanDoubleSlash = true,
		CanSpin = true,
		CanComputePath = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function MopNinja:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(_G.time(spawnDelay), function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function MopNinja:InDoubleSlashRange(): number
	return if self.Blackboard.TargetDistance <= self.DoubleSlashRange then 1 else 2
end

function MopNinja:InSpinRange(): number
	return if self.Blackboard.TargetDistance <= self.SpinRange then 1 else 2
end

function MopNinja:DoubleSlash(): number
	local ogPos = self.Model.PrimaryPart.Position
	local hum = self.Blackboard.Target.Character.Humanoid
	local prediction = hum.MoveDirection.Unit * hum.WalkSpeed * 0.5
	if prediction.Magnitude ~= 1 then prediction = Vector3.new() end
	self.RigMover:MoveTo(
		self.Blackboard.Target.Character.PrimaryPart.Position + prediction - self.Model.PrimaryPart.CFrame.LookVector,
		self.WalkSpeed * 5
	)
	task.wait(_G.time(0.2))
	self.Sink["DoubleSlash"]:FireAllClients()
	self.Blackboard:StartCooldown("CanDoubleSlash", _G.time(5.0))
	task.wait(_G.time(0.75))
	self.RigMover:MoveTo(ogPos, self.WalkSpeed * 5)
	task.wait(_G.time(0.5))
	return self.Blackboard.SUCCESS
end

function MopNinja:Spin(): number
	self.Sink["Spin"]:FireAllClients()
	self.Blackboard:StartCooldown("CanSpin", _G.time(0.5))
	return self.Blackboard.SUCCESS
end

function MopNinja:Die()
	self.Sink["Die"]:FireAllClients()
	if self.AILoop then self.AILoop:Disconnect() end
	self.RigMover:Destroy()
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
		end
	end
	task.wait(_G.time(1.0))
	self.Model:Destroy()
end

function MopNinja:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return MopNinja