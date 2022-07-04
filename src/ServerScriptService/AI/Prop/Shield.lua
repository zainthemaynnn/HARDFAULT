--!strict
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local AI = script.Parent.Parent
local AILoop = require(AI.AILoop)
local BHTCreator = require(ReplicatedStorage.Packages.BehaviorTreeCreator)
local CharControl = require(ServerScriptService.Loadout.CharControl)
local EntityBlackboard = require(AI.EntityBlackboard)
local HpModule = require(AI.HpModule)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local RigMover = require(AI.RigMover)
local Sink = require(ReplicatedStorage.Sink)

local WALKSPEED = 8.0

local BURST_SPEED = 20.0
local BURST_FIRERATE = 0.1
local BURST_COUNT = 3
local BURST_DELAY = 0.2
local BURST_INACCURACY = math.rad(10.0)

local Shield = {}
Shield.__index = Shield
Shield.Name = "Shield"
Shield.BestiaryIndex = 1
Shield.BaseHp = 60
Shield.PreferredRange = 16.0
Shield.Resistances = {
	Ballistic = 0,
	Energy = 1,
	Chemical = 1,
	Fire = 1,
	Stagger = 1,
	Knockback = 1,
}
Shield.FlavorText = [[
Digital assistant equipped with a burst rifle. They fire with some inaccuracy.

One great thing about robots is that you can always program them to do something else they weren't built to do.
]]

Shield.BaseModel = ServerStorage.Props.Shield
Shield.SinkService = Sink:CreateService("Shield", {
	"Spawn",
	"TakeDamage",
	"Die",
})

function Shield.new(room: any, target: Model)
	local self = setmetatable({}, Shield)

	-- meta
	self.Model = self.BaseModel:Clone()
	local cf, size = target:GetBoundingBox()
	local dim = math.max(math.max(size.X, size.Y), size.Y) * math.sqrt(2)/2
	self.Model.PrimaryPart.Size = Vector3.new(dim, dim, dim)
	local weld = Instance.new("WeldConstraint", self.Model.PrimaryPart)
	weld.Part0 = self.Model.PrimaryPart
	weld.Part1 = target.PrimaryPart

	self.HpModule = HpModule.new(self.BaseHp, self.Resistances, self.Model)
	self.WalkSpeed = WALKSPEED
	self.Room = room
	self.Rng = Random.new()

	-- model
	self.Model.Name = self.Name
	self.Model.Parent = ReplicatedStorage
	self.Size = self.Model:GetExtentsSize()

	self.Sink["TakeDamage"]:Connect(function(...)
		self.HpModule:TakeUserDamage(...)
	end)

	self.HpModule.Died:Connect(function() self:Die() end)

	return self
end

function Shield:Spawn()
	self.Sink["Spawn"]:FireAllClients(self.Model)
	self.Model.Parent = workspace
end

function Shield:Die()
	self.Sink["Die"]:FireAllClients()
	self.Model:Destroy()
end

function Shield:Destroy()
	if not self.HpModule.Dead then self:Die() end
	self.Sink:Destroy()
end

return Shield