local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Beam = require(ReplicatedStorage.Effects.Beam)
local Sink = require(ReplicatedStorage.Sink)

Sink:GetService("Lasers"):Sync(function(sink: any, model: Model)
	-- body
end)
