local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Beam = require(ReplicatedStorage.Effects.Beam)
local localPlayer = Players.LocalPlayer

local SpectraV = {}
SpectraV.__index = SpectraV

SpectraV.Telepart = (function()
	local pt = Instance.new("Part")
	pt.Shape = Enum.PartType.Ball
	pt.Color = Color3.new(1, 0, 1)
	pt.Size = Vector3.new(2, 2, 2)
	pt.Material = Enum.Material.Neon
	pt.Anchored = true
	pt.CanCollide = false
	return pt
end)()

function SpectraV.new(sink, model)
	local self = setmetatable({}, SpectraV)

	self.Sink = sink
	self.Model = model
	self.Animator = AnimationHandler.new(model, model:FindFirstChild("Animations"))
	self.AimBeam = nil

	self.Sink:Get("Spawn"):Connect(function(...) self:Spawn(...) end)
	self.Sink:Get("TakeDamage"):Connect(function(...) self:TakeDamage(...) end)
	self.Sink:Get("Teleport"):Connect(function(...) self:Teleport(...) end)
	self.Sink:Get("Target"):Connect(function(...) self:Target(...) end)
	self.Sink:Get("Beam"):Connect(function(...) self:Beam(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)
	return self
end

function SpectraV:Spawn(pos: Vector3, size: Vector3, spawnDelay: number)
	-- body
end

function SpectraV:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

-- teleport after every attack
function SpectraV:Teleport(pos0: Vector3, pos1: Vector3, tpDelay: number)
	local pt = self.Telepart:Clone()
	pt.Position = pos0
	pt.Parent = workspace

	local tw = TweenService:Create(pt, TweenInfo.new(tpDelay), { Position = pos1 })
	tw:Play()
	tw.Completed:Wait()
	tw:Destroy()
	pt:Destroy()
end

local castParams = RaycastParams.new()
castParams.CollisionGroup = "NPC"

local visualCastParams = RaycastParams.new()
visualCastParams.CollisionGroup = "Pierce"

-- show warning laser path
function SpectraV:Target(target: Player, duration: number, delay: number)
	local conn do
		conn = RunService.Heartbeat:Connect(function()
			if self.AimBeam then self.AimBeam:Destroy() end

			local pos0 = self.Model.PrimaryPart.Position
			local dir = (target.Character.PrimaryPart.Position - pos0).Unit * 50.0

			local pierceRes = workspace:Raycast(
				pos0,
				dir,
				visualCastParams
			)

			self.AimBeam = Beam.new(
				(function()
					local beam = Instance.new("Beam", workspace)
					beam.Texture = "http://www.roblox.com/asset/?id=109635220"
					beam.Color = ColorSequence.new(Color3.new(.7, 0, .7))
					beam.Width0 = 0.4
					beam.Width1 = 0.4
					return beam
				end)(),
				pos0,
				if pierceRes then pierceRes.Position else pos0 + dir
			)
		end)
		task.delay(_G.time(duration), function()
			conn:Disconnect()
		end)
	end
end

-- fire laser
function SpectraV:Beam(target: Player, delay: number)
	local pos0 = self.Model.PrimaryPart.Position
	local char = target.Character
	local dir = (char.PrimaryPart.Position - pos0).Unit * 50.0

	task.delay(delay)
	if self.AimBeam then self.AimBeam:Destroy() end

	local pierceRes = workspace:Raycast(
		pos0,
		dir,
		visualCastParams
	)

	local beam = Instance.new("Beam", workspace)
	beam.Texture = "http://www.roblox.com/asset/?id=109635220"
	beam.Color = ColorSequence.new(Color3.new(1, 0, 1))
	beam.Width0 = 0.5
	beam.Width1 = 0.5

	Beam.new(
		beam,
		pos0,
		if pierceRes then pierceRes.Position else pos0 + dir
	):FadeOut(
		TweenInfo.new()
	)

	local res = workspace:Raycast(
		pos0,
		dir,
		castParams
	)

	if target == localPlayer and res and res.Instance:FindFirstAncestorWhichIsA("Model") == char then
		self.Sink["BeamHit"]:FireServer(char:FindFirstChildWhichIsA("Humanoid"))
	end
end

function SpectraV:Die()
	-- body
end

return SpectraV