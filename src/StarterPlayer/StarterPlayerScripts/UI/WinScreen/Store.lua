local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Sink = require(ReplicatedStorage.Sink)

local function BestiaryReducer(state, action)
	return {}
end

local store = Rodux.Store.new(function(state, action)
	return BestiaryReducer(state, action)
end)

return store