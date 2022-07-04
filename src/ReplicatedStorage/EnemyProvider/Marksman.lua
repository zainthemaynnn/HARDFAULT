local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Beam = require(ReplicatedStorage.Effects.Beam)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local Marksman = {}
Marksman.__index = Marksman

Marksman.AimBeamInstance = (function()
	local beam = Instance.new("Beam", workspace.Junk)
	beam.Texture = "http://www.roblox.com/asset/?id=109635220"
	beam.Color = ColorSequence.new(BrickColor.new("Electric blue").Color)
	beam.Width0 = 0.4
	beam.Width1 = 0.4
	return beam
end)()

Marksman.VisualCastParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "Pierce"
	return params
end)()

function Marksman.new(sink: any, model: Model)
	local self = setmetatable({}, Marksman)

	self.Model = model
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.WeaponMuzzle = self.Model.Pistol.Muzzle
	self.AimBeam = Beam.new(self.AimBeamInstance)

	self.CastBehavior = Projectiles.Caster.stdBehavior("NPCProjectile", Projectiles.partcache(Projectiles.BlueOrb, 1))
	self.Caster = Projectiles.Caster.new()
	self.Caster.RayHit:Connect(function(cast: any, result: RaycastResult)
		if cast.Subject then
			cast.Subject:TakeDamage({
				Type = "Projectile",
				Cast = cast,
				Hit = result,
				Amount = 30,
			})
		end
	end)

	return self
end

function Marksman:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function Marksman:Run(enable: boolean)
	if enable then
		self.Animator:Play("Run")
	else
		self.Animator:Stop("Run")
	end
end

function Marksman:Snipe(target: Player, charge: number, delay: number)
	self.AimBeam:SetEnabled(true)
	local dir
	local aimConn do
		aimConn = RunService.RenderStepped:Connect(function()
			local pos0 = self.WeaponMuzzle.Position
			local pos1 = target.Character.PrimaryPart.Position
			pos0 = self.WeaponMuzzle.Position
			dir = (pos1 - pos0).Unit * 999
			self.AimBeam:VisualRaycast(pos0, dir, self.VisualCastParams)
		end)
	end

	task.wait(_G.time(charge))
	aimConn:Disconnect()

	task.wait(_G.time(delay))
	self.AimBeam:SetEnabled(false)
	self.Caster:Fire(self.WeaponMuzzle.Position, dir, 100.0, self.CastBehavior)

end

function Marksman:Die()
	-- body
end

return Marksman