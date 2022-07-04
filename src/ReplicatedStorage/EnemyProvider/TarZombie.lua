local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Hitbox = require(ReplicatedStorage.Effects.Hitbox)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local localPlayer = Players.LocalPlayer

local TarZombie = {}
TarZombie.__index = TarZombie

local HIT_SOUNDS = {
	"Flesh 1",
	"Flesh 2",
	"Flesh 3",
	"Flesh 4",
	"Flesh 5",
}

function TarZombie.new(sink, model)
	local self = setmetatable({}, TarZombie)
	
	self.Model = model
	self.Sink = sink
	self.ArmHitbox = Hitbox.create(model.LeftHand)
	self.Animator = AnimationHandler.new(model, model:FindFirstChild("Animations"))
	self.Rng = Random.new()
	self.Sink:Get("Spawn"):Connect(function(...) self:Spawn(...) end)
	self.Sink:Get("TakeDamage"):Connect(function(...) self:TakeDamage(...) end)
	self.Sink:Get("Slash"):Connect(function(...) self:Slash(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)
	return self
end

function TarZombie:Spawn(model: Model, spawnDelay: number)
	SpawnIndicator.smoke(model, spawnDelay)
	self.Animator:Play("Idle")
end

function TarZombie:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):Fire(amount, dealer)
	SFX:Play(HIT_SOUNDS[self.Rng:NextInteger(1, 5)])
end

function TarZombie:Slash(duration: number?)
	local hitbox = self.ArmHitbox
	local track = self.Animator:GetTrack("Slash")
	if not track then return error("Missing attack animation.") end
	track:Play("Slash", duration)
	hitbox:HitStart(track.Length)
	hitbox.OnHit:Connect(function(hit, hum)
		if hum.Parent == localPlayer.Character then
	    	self.Sink:Get("SlashHit"):FireServer(hum)
	    end
	end)
end

function TarZombie:Die()
	-- body
end

return TarZombie