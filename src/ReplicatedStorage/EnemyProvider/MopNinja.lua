local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local CEnum = require(ReplicatedStorage.CEnum)
local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local MopNinja = {}
MopNinja.__index = MopNinja

MopNinja.Projectile = Projectiles.BlueOrb

function MopNinja.new(sink: any, model: Model)
	local self = setmetatable({}, MopNinja)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.Animator:GetTrack("DoubleSlash").KeyframeReached:Connect(function(k)
		if k == "Slash1Start" or k == "Slash2Start" then
			self.MopHitbox:HitStart()
		elseif k == "Slash1End" or k == "Slash2End" then
			self.MopHitbox:HitStop()
		end
	end)

	self.Animator:GetTrack("Spin").KeyframeReached:Connect(function(k)
		if k == "SpinStart" then
			self.MopHitbox:HitStart()
		elseif k == "SpinEnd" then
			self.MopHitbox:HitStop()
		end
	end)

	self.MopHitbox = RaycastHitbox.new(self.Model.Mop.Handle)
	self.MopHitbox.OnHit:Connect(function(hit: Part)
		if Projectiles.localHit(hit) then
			self.Sink:Get("DoubleSlashHit"):FireServer()
		end
	end)

	self.Caster, self.CastBehavior = Projectiles.caster(
		Projectiles.partcache(self.Projectile, 10),
		"NPCProjectile"
	)

	self.Caster.RayHit:Connect(function(_: any, result: RaycastResult)
		if Projectiles.localHit(result.Instance) then
			self.Sink:Get("SpreadHit"):FireServer(Players.LocalPlayer)
		end
	end)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.smoke)
	self.Sink:Get("DoubleSlash"):Connect(function(...) self:DoubleSlash(...) end)
	self.Sink:Get("Spin"):Connect(function(...) self:Spin(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)

	return self
end

function MopNinja:Run(enabled: boolean)
	if enabled then
		self.Animator:PlayIfNotPlaying("Run")
	else
		self.Animator:Stop("Run")
	end
end

function MopNinja:TakeDamage(dmg: any): string
	self.Sink:Get("TakeDamage"):FireServer(dmg.Amount)
	return CEnum.HitResult.Success
end

function MopNinja:DoubleSlash()
	self.Animator:Play("DoubleSlash")
end

function MopNinja:Spin()
	self.Animator:Play("Spin")
end

function MopNinja:Stars(target: Player, speed: number, count: number, spread: number, delay: number)
	task.wait(_G.time(delay))

end

function MopNinja:Die()
	-- body
end

return MopNinja