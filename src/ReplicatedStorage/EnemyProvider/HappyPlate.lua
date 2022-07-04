local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Explosion = require(ReplicatedStorage.Effects.Explosion)
local Hitbox = require(ReplicatedStorage.Effects.Hitbox)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local LocalPlayer = Players.LocalPlayer

local HappyPlate = {}
HappyPlate.__index = HappyPlate

local EXPLODE_RANGE = 4.0
local HIT_SOUNDS = {
	"Flesh 1",
	"Flesh 2",
	"Flesh 3",
	"Flesh 4",
	"Flesh 5",
}

HappyPlate.ExplodeParams = (function()
	local params = OverlapParams.new()
	params.CollisionGroup = "NPCSensProjectile"
	return params
end)()

function HappyPlate.new(name, sink, model)
	local self = setmetatable({}, HappyPlate)
	
	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)
	self.Rng = Random.new()
	self.DetectionLoop = nil
	self.Sink:Get("Spawn"):Connect(function(...) self:Spawn(...) end)
	self.Sink:Get("TakeDamage"):Connect(function(...) self:TakeDamage(...) end)
	self.Sink:Get("Explode"):Connect(function(...) self:Explode(...) end)
	return self
end

function HappyPlate:Spawn(spawnDelay: number)
	task.wait(_G.time(spawnDelay))
	self.DetectionLoop = RunService.Heartbeat:Connect(function()
		if self:CheckBounds() then
			self.DetectionLoop:Disconnect()
			self.DetectionLoop = nil
			self.Sink:Get("Explode"):FireServer()
		end
	end)
end

function HappyPlate:CheckBounds()
	return #workspace:GetPartBoundsInRadius(
		self.Model.PrimaryPart.Position,
		EXPLODE_RANGE,
		self.ExplodeParams
	) > 0
end

function HappyPlate:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):Fire(amount, dealer)
	SFX:Play(HIT_SOUNDS[self.Rng:NextInteger(1, 5)])
end

function HappyPlate:Explode(radius: number, duration: number, fade: number)
	SFX:Play("Boom")
	local explosion = Explosion.new(
		self.Model.PrimaryPart.Position,
		radius,
		duration,
		fade,
		self.ExplodeParams,
		BrickColor.new("Teal").Color
	)
	explosion.Hit:Connect(function(parts: {Part})
		local hit = {}
		for _, part in pairs(parts) do
			local plr = Players:GetPlayerFromCharacter(part:FindFirstAncestorWhichIsA("Model"))
			if plr and not hit[plr] then
				self.Sink["ExplodeHit"]:FireServer(plr)
				hit[plr] = true
			end
		end
	end)
	explosion.Finished:Connect(function()
		self:Destroy()
	end)
end

function HappyPlate:Destroy()
	if self.DetectionLoop then self.DetectionLoop:Disconnect() end
end

return HappyPlate