local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sink = require(ReplicatedStorage.Sink)

local WeaponProvider = {}
WeaponProvider.__index = WeaponProvider

return setmetatable(Sink.provider(script:GetChildren()), WeaponProvider)