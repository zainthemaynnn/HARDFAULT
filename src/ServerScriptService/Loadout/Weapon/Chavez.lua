local HTTP = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CEnum = require(ReplicatedStorage.CEnum)
local PickupPrompt = require(script.Parent.Parent.PickupPrompt)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local Sink = require(ReplicatedStorage.Sink)

local Chavez = {}
Chavez.__index = Chavez

Chavez.BaseModel = ServerStorage.Accessories.Chavez
Chavez.Name = "Chavez"
Chavez.EquipSound = (function()
	local sound = Instance.new("Sound")
	sound.SoundId = 6911756259
	return sound
end)()
Chavez.InteractSound = (function()
	local sound = Instance.new("Sound")
	sound.SoundId = 6911756959
	return sound
end)()
Chavez.HealValue = 50
Chavez.SinkService = Sink:CreateService("Chavez", {})

function Chavez.new()
	local self = setmetatable({}, Chavez)

	self.Name = self.BaseName .. "_" .. HTTP:GenerateGUID(false)
	self.Model = self.BaseModel:Clone()
	self.Model.Parent = ReplicatedStorage

	self.Sink = self.SinkService:Relay(
		self.Model
	)

	self.EquipSound = self.EquipSound:Clone()
	self.EquipSound.Parent = self.Model.PrimaryPart
	self.InteractSound = self.InteractSound:Clone()
	self.InteractSound.Parent = self.Model.PrimaryPart

	self.PickupPrompt = PickupPrompt.new(self)
	self.PickupPrompt.Equipped:Connect(function() self:Equip() end)

	return self
end

function Chavez:Equip(_: Player)
	self.EquipSound:Play()
end

function Chavez:Use(plr: Player)
	self.InteractSound:Play()
	self.Owner.HpModule:Heal(self.HealValue)
	self.Sink["Use"]:FireAllClientsExcept(plr)
	self.Owner:SwapItem(nil)
	self:Destroy()
end

function Chavez:Destroy()
	self.Model:Destroy()
	self.PickupPrompt:Destroy()
end

return Chavez