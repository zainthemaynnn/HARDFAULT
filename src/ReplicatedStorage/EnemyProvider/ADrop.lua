local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Explosion = require(ReplicatedStorage.Effects.Explosion)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)
local Projectiles = require(ReplicatedStorage.Projectiles)
local SFX = require(ReplicatedStorage.Effects.SFX)
local SpawnIndicator = require(ReplicatedStorage.Effects.SpawnIndicator)

local ADrop = {}
ADrop.__index = ADrop

ADrop.BombModel = (function()
	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1,1,1)
	part.BrickColor = BrickColor.new("Electric blue")
	part.Anchored = true
	part.Material = Enum.Material.Neon
	PhysicsService:SetPartCollisionGroup(part, "NPCProjectile")
	return part
end)()
ADrop.BombExplodeParams = (function()
	local params = OverlapParams.new()
	params.CollisionGroup = "NPCProjectile"
	return params
end)()

function ADrop.new(sink: any, model: Model)
	local self = setmetatable({}, ADrop)

	self.Model = model
	self.Size = self.Model:GetExtentsSize()
	self.Sink = sink
	self.Animator = AnimationHandler.new(
		Instance.new("AnimationController", model),
		model:FindFirstChild("Animations"):GetChildren()
	)

	self.Sink:Get("Spawn"):Connect(SpawnIndicator.teleport)
	self.Sink:Get("Bomb"):Connect(function(...) self:DeployBomb(...) end)
	self.Sink:Get("Run"):Connect(function(...) self:Run(...) end)

	return self
end

function ADrop:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function ADrop:Run()
	-- body
end

function ADrop:Detonate(bomb: Part, radius: number)
	local explosion = Explosion.new(self.BombExplodeParams, false, BrickColor.new("Electric blue").Color)
	explosion:Spawn(bomb.Position, radius, 0, 0.5)
	local hitConn do
		hitConn = explosion.Hit:Connect(function(colliding: {Part})
			for _, p in pairs(colliding) do
				if Projectiles.localHit(p) then
					hitConn:Disconnect()
					self.Sink:Get("BombHit"):FireServer(Players.LocalPlayer)
				end
			end
		end)
	end

	bomb:Destroy()
	SFX:Play("Zap")
end

function ADrop:DeployBomb(lifetime: number, radius: number)
	local bomb = self.BombModel:Clone()
	bomb.Position = self.Model.PrimaryPart.Position - Vector3.new(0, self.Size.Y/2, 0)
	bomb.Parent = workspace

	local exploded = false

	-- TODO: replicate this!
	local touchConn do
		touchConn = bomb.Touched:Connect(function(hit: Part)
			if Projectiles.localHit(hit) then
				touchConn:Disconnect()
				exploded = true
				self:Detonate(bomb, radius)
			end
		end)
	end

	task.delay(lifetime, function()
		touchConn:Disconnect()
		if exploded then return end
		self:Detonate(bomb, radius)
	end)
end


function ADrop:Die()
	self:Destroy()
end

function ADrop:Destroy()
	-- body
end

return ADrop