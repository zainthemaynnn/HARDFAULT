local HTTP = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local PickupPrompt = require(script.Parent.Parent.PickupPrompt)
local SFX = require(ReplicatedStorage.Effects.SFX)
local Sink = require(ReplicatedStorage.Sink)

local BloxyCola = {}
BloxyCola.__index = BloxyCola

BloxyCola.BaseModel = ServerStorage.Accessories.BloxyCola
BloxyCola.Name = "BloxyCola"
BloxyCola.HealValue = 20
BloxyCola.SinkService = Sink:CreateService("BloxyCola", {})

function BloxyCola.new()
	local self = setmetatable({}, BloxyCola)

	self.Model = self.BaseModel:Clone()
	self.Model.Parent = ReplicatedStorage

	self.Sink = self.SinkService:Relay(
		self.Model
	)

	self.PickupPrompt = PickupPrompt.new(self)
	self.PickupPrompt.Equipped:Connect(function() self:Equip() end)

	return self
end

function BloxyCola:Equip(_: Player)
	SFX:Play("Soda crackle")
end

function BloxyCola:Use(plr: Player)
	SFX:Play("Slurrrp, AHH")
	self.PickupPrompt.Owner.HpModule:Heal(self.HealValue)
	self.PickupPrompt.Owner:SwapItem(nil)
	self:Destroy()
end

function BloxyCola:Destroy()
	self.Model:Destroy()
	self.PickupPrompt:Destroy()
end

return BloxyCola