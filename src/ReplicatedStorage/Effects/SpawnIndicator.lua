local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local SFX = require(ReplicatedStorage.Effects.SFX)

local SpawnIndicator = {}
SpawnIndicator.__index = SpawnIndicator

local spawnPart = (function()
	local part = Instance.new("Part")
	part.CanCollide = false
	part.Anchored = true
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.SmoothPlastic
	return part
end)()

function SpawnIndicator.smoke(cf: CFrame, model: Model, spawnDelay: number)
	local size = model:GetExtentsSize()
	local radius = math.max(size.X, size.Z)*math.sqrt(2)
	cf = cf * CFrame.Angles(0, 0, math.rad(90))

	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Disc
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	emitter.ShapeInOut = Enum.ParticleEmitterShapeInOut.Outward
	emitter.EmissionDirection = Enum.NormalId.Right
	emitter.ShapePartial = 1.0
	emitter.Color = ColorSequence.new(BrickColor.new("Really black").Color)
	emitter.Size = NumberSequence.new(2, 3)
	emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
	emitter.Speed = NumberRange.new(size.Y)
	emitter.Lifetime = NumberRange.new(1)
	emitter.Rate = size.Y
	emitter.Enabled = true

	local bg = spawnPart:Clone()
	bg.CFrame = cf
	bg.Size = Vector3.new(0.05, radius, radius)
	bg.Color = BrickColor.new("Really black").Color
	bg.Transparency = .5
	bg.Parent = workspace.Junk

	local p = spawnPart:Clone()
	p.CFrame = cf
	p.Size = Vector3.new(0.05, 0.05, 0.05)
	p.Color = BrickColor.new("Really black").Color
	emitter.Parent = p
	p.Parent = workspace.Junk

	local tw0 = TweenService:Create(p, TweenInfo.new(spawnDelay, Enum.EasingStyle.Linear), { Size = bg.Size })
	tw0:Play()
	tw0.Completed:Wait()

	SFX:Play("VoidSpawn")

	bg:Destroy()
	p:Destroy()
end

function SpawnIndicator.teleport(cf: CFrame, model: Model, spawnDelay: number)
	local size = model:GetExtentsSize()
	local radius = math.max(size.X, size.Z)*math.sqrt(2)
	cf = cf * CFrame.Angles(0, 0, math.rad(90))

	local bg = spawnPart:Clone()
	bg.CFrame = cf
	bg.Size = Vector3.new(0.05, radius, radius)
	bg.Color = BrickColor.new("Institutional white").Color
	bg.Transparency = .5
	bg.Parent = workspace.Junk

	local p = spawnPart:Clone()
	p.CFrame = cf
	p.Size = Vector3.new(0.05, 0.05, 0.05)
	p.Color = BrickColor.new("Institutional white").Color
	p.Parent = workspace.Junk

	local tw0 = TweenService:Create(p, TweenInfo.new(spawnDelay, Enum.EasingStyle.Linear), { Size = bg.Size })
	tw0:Play()
	task.wait(spawnDelay)
	SFX:Play("TeleSpawn")

	bg:Destroy()
	p.Position += Vector3.new(0, size.Y/2, 0)
	p.Size += Vector3.new(size.Y, 0, 0)
	local tw1 = TweenService:Create(p, TweenInfo.new(), { Transparency = 1 })
	tw1:Play()
	tw1.Completed:Wait()
	p:Destroy()
end

return SpawnIndicator