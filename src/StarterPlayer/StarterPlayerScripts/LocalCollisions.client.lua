local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Sink = require(ReplicatedStorage.Sink)

local UNLOCKED_TRANSPARENCY = .5

Sink:GetService("Doors"):Sync(function(sink: any, model: Model)
	local parts = {}
	for _, p in pairs(model:GetDescendants()) do
		if p:IsA("BasePart") then table.insert(parts, p) end
	end
	sink:Get("Lock"):Connect(function()
		for _, pt in pairs(parts) do
			--PhysicsService:SetPartCollisionGroup(pt, "Default")
			TweenService:Create(pt, TweenInfo.new(), { Transparency = 0 }):Play()
		end
	end)
	sink:Get("Unlock"):Connect(function()
		for _, pt in pairs(parts) do
			PhysicsService:SetPartCollisionGroup(pt, "Door")
			TweenService:Create(pt, TweenInfo.new(), { Transparency = UNLOCKED_TRANSPARENCY }):Play()
		end
	end)
end)

Sink:GetService("Room"):Sync(function(sink: any, model: Model)
	local active = false
	sink:Get("LightingOn"):Connect(function(light: SurfaceLight, flash: boolean)
		light.Enabled = true
		active = true

		if flash then
			print(flash, active)
			while active do
				local tw
				tw = TweenService:Create(light, TweenInfo.new(), { Brightness = 1 })
				tw:Play()
				tw.Completed:Wait()
				tw = TweenService:Create(light, TweenInfo.new(), { Brightness = 0.2 })
				tw:Play()
				tw.Completed:Wait()
			end
		end
	end)

	sink:Get("LightingOff"):Connect(function(light: SurfaceLight)
		light.Enabled = false
		active = false
	end)
end)

local DamageIndicator = require(ReplicatedStorage.Effects.DamageIndicator)
Sink:GetService("Hp"):Sync(function(sink: any)
	sink:Get("DamageIndicator"):Connect(function(amount: number, mult: number, pos: Vector3)
		DamageIndicator.new(amount, mult):Spawn(pos)
	end)
end)
