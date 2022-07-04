local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)

local function reducer(state, action)
	state = state or {}
    return state
end

local store = Rodux.Store.new(function(state, action)
	if not state then
		return {}
	else
		return {}
	end
end)

return store