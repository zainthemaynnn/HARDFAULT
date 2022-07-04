local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CharControl = require(ServerScriptService.Loadout.CharControl)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local Signal = require(ReplicatedStorage.Packages.Signal)

local ACTIVATION_DISTANCE = 8.0

local PickupPrompt = {}
PickupPrompt.__index = PickupPrompt
PickupPrompt._Prompt = (function()
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Take"
	prompt.AutoLocalize = true
	prompt.RequiresLineOfSight = false
	prompt.MaxActivationDistance = ACTIVATION_DISTANCE
	prompt.Enabled = true
	return prompt
end)()

function PickupPrompt.new(item: any)
	local self = setmetatable({}, PickupPrompt)
	self.Weapon = item
	self.Owner = nil

	self._Prompt = self._Prompt:Clone()
	self._Prompt.Parent = item.Model.PrimaryPart
	self._Prompt.ObjectText = item.Name

	self._OnTrigger = self._Prompt.Triggered:Connect(function(plr: Player)
		local plrData = PlayerData[plr.UserId]
		self.Owner = plrData
		plrData:SwapItem(item)
	end)

	self.Equipped, self.Dropped = Signal.new(), Signal.new()
	return self
end

function PickupPrompt:Equip(plr: Player)
	CharControl.addCustomAccessory(plr.Character, self.Weapon.Model)
	self._Prompt.Enabled = false
	self.Equipped:Fire(plr)
end

function PickupPrompt:Unequip()
	CharControl.unweldCustomAccessory(self.Weapon.Model)
	self._Prompt.Enabled = true
	self.Owner = nil
	self.Dropped:Fire()
end

function PickupPrompt:Destroy()
	self._OnTrigger:Disconnect()
	self._Prompt:Destroy()
	self.Equipped:DisconnectAll()
	self.Dropped:DisconnectAll()
end

return PickupPrompt