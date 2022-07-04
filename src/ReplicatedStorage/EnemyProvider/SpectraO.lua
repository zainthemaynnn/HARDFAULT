local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AnimationHandler = require(ReplicatedStorage.Effects.AnimationHandler)
local Beam = require(ReplicatedStorage.Effects.Beam)
local FastCast = require(ReplicatedStorage.Packages.FastCast)
local PartCache = require(ReplicatedStorage.Packages.PartCache)

local LocalPlayer = Players.LocalPlayer

local SpectraO = {}
SpectraO.__index = SpectraO

function SpectraO.new(name, sink, model)
	local self = setmetatable({}, SpectraO)
	
	self.Sink = sink
	self.Model = model
	self.Animator = AnimationHandler.new(model, model:FindFirstChild("Animations"))
	self.Sink:Get("Spawn"):Connect(function(...) self:Spawn(...) end)
	self.Sink:Get("TakeDamage"):Connect(function(...) self:TakeDamage(...) end)
	self.Sink:Get("Die"):Connect(function(...) self:Die(...) end)
	return self
end

function SpectraO:Spawn(pos: Vector3, size: Vector3, spawnDelay: number)
	-- body
end

function SpectraO:TakeDamage(amount: number, dealer: Player?)
	self.Sink:Get("TakeDamage"):FireServer(amount, dealer)
end

function SpectraO:Die()
	-- body
end

return SpectraO