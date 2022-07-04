local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local PlayerData = require(ServerScriptService.Game.PlayerData)
local Sink = require(ReplicatedStorage.Sink)

local ACTIVATION_DISTANCE = 4.0

local AmmoPickup = {}
AmmoPickup.__index = AmmoPickup

AmmoPickup.BaseModel = ServerStorage.AmmoPickup
AmmoPickup.Prompt = (function()
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take"
	prompt.AutoLocalize = true
	prompt.ObjectText = "Magazine"
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = ACTIVATION_DISTANCE
	prompt.Enabled = true
	return prompt
end)()

function AmmoPickup.new(pos: Vector3, value: number)
	local self = setmetatable({}, AmmoPickup)
	self.Model = AmmoPickup.BaseModel:Clone()
	self.Value = value
	self._Prompt = self.Prompt:Clone()
	self._Prompt.Parent = self.Model
	self.Model.Parent = workspace
	self.Model:MoveTo(pos)
	self.Ontrigger = self._Prompt.Triggered:Connect(function(plr: Player) AmmoPickup:Collect(plr) end)
	return self
end

function AmmoPickup:Collect(plr: Player)
	local plrData = PlayerData[plr.UserId]
	if not plrData:GetItem() then return end
	plrData:Restock(self.Value)
	self:Destroy()
end

function AmmoPickup:Destroy()
	self._Prompt:Destroy()
	self._OnTrigger:Disconnect()
end

return AmmoPickup