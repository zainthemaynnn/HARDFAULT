--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local CharControl = require(ServerScriptService.Loadout.CharControl)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local Pathing = require(AI.Pathing)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local Projectiles = require(ReplicatedStorage.Projectiles)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 3.0
local SPIN_WALKSPEED = 20.0

local Dancer = {}
Dancer.__index = Dancer
Dancer.Name = "Dancer"
Dancer.BaseHp = 1
Dancer.BestiaryIndex = 2
Dancer.Resistances = {
	Ballistic = .2,
	Energy = .2,
}
Dancer.FlavorText = [[
Agile humanoid that spins to different locations.

What do you mean "Critical Strike?" You're tripping.
]]

Dancer.PreferredRange = 10.0
Dancer.BaseModel = ServerStorage.Enemies.Dancer
for _, p in pairs(Dancer.BaseModel:GetDescendants()) do
	if p:IsA("BasePart") then
		PhysicsService:SetPartCollisionGroup(p, "NPC")
		p.CanCollide = true
	end
end
Dancer.SinkService = Sink:CreateService("Dancer", {
	"Spawn",
	"TakeDamage",
	"Run",
	"Spin",
	"SpinHit",
	"EndSpin",
	"ReturnOrb",
	"ReturnHit",
	"Bomb",
	"BombHit",
	"Die",
})

function Dancer.new(room)
	local self = setmetatable({}, Dancer)

	-- meta
	self.HpModule = HpModule.new(self.BaseHp)
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

	self.Bombs = Projectiles.partcache(Projectiles.RedOrb, 20)

	self.Sink["TakeDamage"]:Connect(function(plr: Player, dmg: number)
		self:TakeDamage(plr, dmg)
	end)

	self.Sink["SpinHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId].HpModule:TakeDamage(5)
	end)

	self.Sink["BombHit"]:Connect(function(plr: Player)
		PlayerData[plr.UserId].HpModule:TakeDamage(10)
	end)

	-- AI
	self.AILoop = nil
	self.Behavior = BHTCreator:Create(Dancer.BaseModel.Dancer)
	self.Blackboard = EntityBlackboard.new({
		Target = nil,
		TargetDistance = math.huge,
		InPreferredRange = false,
		Seeking = false,
		CanSpin = true,
		Spinning = false,
		CanComputePath = true,
	})

	self.HpModule.Died:Connect(function() self:Die() end)

	-- movement
	self.RigMover = RigMover.new(self.Model, self.WalkSpeed, self.Size)

	self.RigMover:Align(function()
		return self.Blackboard.Target and self.Blackboard.Target.Character.PrimaryPart.Position
	end)

	self.RigMover.MoveBegan:Connect(function()
		self:DeployBomb()
	end)

	return self
end

function Dancer:Spawn(cf: CFrame, spawnDelay: number)
	self.Sink["Spawn"]:FireAllClients(cf, self.Model, spawnDelay)
	task.delay(spawnDelay, function()
		self.Model.Parent = workspace
		self.Model:SetPrimaryPartCFrame(cf)
		self.AILoop = AILoop.Stepped:Connect(function() self.Behavior:run(self) end)
	end)
end

function Dancer:LookAt(pos: Vector3)
	self.RigMover:LookAt(pos)
end

function Dancer:TakeDamage(plr: Player, dmg: number)
	if self.Blackboard.Spinning then
		local dir = self.Rng:NextUnitVector() * Vector3.new(1, 0, 1)
		self.Sink["ReturnOrb"]:FireAllClients(dmg, dir)
	else
		self.HpModule:TakeUserDamage(dmg, plr)
	end
end

function Dancer:SpinTo(pos: Vector3, continuous: boolean?, acceleration: number?)
	continuous = continuous or false

	self.Sink["Spin"]:FireAllClients()

	if acceleration then
		self.RigMover:AccelerateTo(pos, acceleration, SPIN_WALKSPEED)
	else
		self.RigMover:MoveTo(pos, SPIN_WALKSPEED)
	end

	if continuous == false then
		local conn do
			conn = self.RigMover.MoveEnded:Connect(function(interrupted)
				if interrupted then return end
				conn:Disconnect()
				self.Blackboard.Spinning = false
				self.Sink["EndSpin"]:FireAllClients()
			end)
		end
	end

	self.Blackboard.Spinning = true
end

function Dancer:BombSpin(): number
	self:SpinTo(self.Room:RandomPos(self.SpinRad))
	task.defer(function()
		local t = 0
		local conn do
			conn = RunService.Heartbeat:Connect(function(dt: number)
				if not self.Blackboard.Spinning then return conn:Disconnect() end
				t += dt
				if t > 0.2 then
					t = 0
					self.Sink["Bomb"]:FireAllClients(Instance.new("Part"), 2.0)
				end
			end)
		end
	end)
	return 1
end

function Dancer:DeployBomb()
	self.Sink["Bomb"]:FireAllClients(self.Bombs:GetPart(), 4.0, 2.0)
end

function Dancer:BatchSpin(): number
	local n = self.Rng:NextInteger(3, 5)
	task.defer(function()
		if n == 1 then
			self:SpinTo(self.Room:RandomPos(3.0), false, SPIN_WALKSPEED)
			self.RigMover.MoveEnded:Wait()
		else
			self:SpinTo(self.Room:RandomPos(3.0), true, SPIN_WALKSPEED)
			self.RigMover.MoveEnded:Wait()
			for _=1,n-2 do
				self:SpinTo(self.Room:RandomPos(3.0), true)
				self.RigMover.MoveEnded:Wait()
			end
			self:SpinTo(self.Room:RandomPos(3.0), false)
			self.RigMover.MoveEnded:Wait()
		end

		self.Blackboard:StartCooldown("CanSpin", 2.0)
	end)
	self.Blackboard.CanSpin = false
	return 1
end

function Dancer:Die()
	self.Sink["Die"]:FireAllClients()
	self.RigMover:Destroy()
	if self.AILoop then self.AILoop:Disconnect() end
	for _, p in pairs(self.Model:GetDescendants()) do
		if p:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(p, "Invulnerable")
		end
	end
	task.wait(_G.time(3.0))
	self.Model:Destroy()
end

function Dancer:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return Dancer