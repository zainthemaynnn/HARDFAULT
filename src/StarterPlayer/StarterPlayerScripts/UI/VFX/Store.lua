local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Sink = require(ReplicatedStorage.Sink)

local function VFXReducer(state, action)
	-- too lazy to put an actual queue here. DWI.
	state = state or {
		Transparency = 1,
		Color = Color3.new(),
		Text = "",
	}

	if action.type == "SetOverlay" then
		return {
			Transparency = action.Transparency or state.Transparency,
			Color = action.Color or state.Color,
			Text = action.Text or state.Text,
		}
	end

	return state
end

local store = Rodux.Store.new(function(state, action)
	return VFXReducer(state, action)
end)

return store