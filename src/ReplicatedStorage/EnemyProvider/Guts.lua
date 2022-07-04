local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Hitbox = require(ReplicatedStorage.Effects.Hitbox)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local localPlayer = Players.LocalPlayer

local Guts = {}
Guts.__index = Guts

local HIT_SOUNDS = {
	"Flesh 1",
	"Flesh 2",
	"Flesh 3",
	"Flesh 4",
	"Flesh 5",
}

Guts.HitParams = (function()
	local params = OverlapParams.new()
	params.CollisionGroup = "NPCProjectile"
	return params
end)()

function Guts.new(name, sink, model)
	local self = setmetatable({}, Guts)

	self.Model = model
	self.Sink = sink
	self.ArmHitbox = Hitbox.create(model.LeftHand)
	self.Animator = AnimationHandler.new(model, model:FindFirstChild("Animations"))
	self.Rng = Random.new()

	self.Sink:Get("Spawn"):Connect(function(...) self:Spawn(...) end)
	self.Sink:Get("TakeDamage"):Connect(function(...) self:TakeDamage(...) end)
	self.Sink:Get("Spray"):Connect(function(...) self:Spray(...) end)
	self.Sink:Get("Cloud"):Connect(function(...) self:Cloud(...) end)
	self.Sink:Get("Sink"):Connect(function(...) self:Sink(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)
	return self
end

function Guts:Spawn(model: Model, spawnDelay: number)
	SpawnIndicator.smoke(model, spawnDelay)
end

function Guts:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):Fire(amount, dealer)
	SFX:Play(HIT_SOUNDS[self.Rng:NextInteger(1, 5)])
end

function Guts:Spray( ... )
	-- body
end

function Guts:Cloud(radius: number, delay: number, duration: number)
	task.wait(_G.time(delay))

	local emitter = Instance.new("ParticleEmitter")
	emitter.Parent = self.Model.Head
	emitter.Color = ColorSequence.new(BrickColor.new("Really black").Color)
	emitter.Size = NumberSequence.new(radius*2)
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Lifetime = NumberRange.new(2)
	emitter.Transparency = NumberRange.new(.2)
	emitter.Speed = NumberRange.new(0)
	emitter.RotSpeed = NumberRange.new(-360, 360)
	emitter.Rate = 2

	local conn do
		RunService.Heartbeat:Connect(function()
			for _, part in workspace:GetPartBoundsInRadius(
				self.Model.Head.Position,
				radius,
				self.HitParams
			) do
				local plr = Players:GetPlayerFromCharacter(part:FindFirstAncestorWhichIsA("Model"))
				if plr == localPlayer then
					self.Sink["CloudHit"]:FireServer()
				end
			end
		end)
	end

	task.wait(_G.time(duration))

	emitter:Destroy()
	conn:Disconnect()
end

function Guts:Sink( ... )
	-- body
end

function Guts:Die()
	-- body
end

return Guts