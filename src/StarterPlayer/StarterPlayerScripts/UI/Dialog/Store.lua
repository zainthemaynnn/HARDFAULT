local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Sink = require(ReplicatedStorage.Sink)

local function DialogReducer(state, action)
	-- too lazy to put an actual queue here. DWI.
	state = state or {
		Queue = {},
		Text = nil,
		Profile = nil,
		Active = false,
	}

	if action.type == "QueueDialog" then
		table.insert(state.Queue, {
			Text = action.Text,
			Profile = action.Profile,
			Timing = action.Timing,
		})
		return state
	elseif action.type == "NextDialog" then
		local dialog = table.remove(state.Queue, 1)
		return {
			Queue = state.Queue,
			Text = dialog and dialog.Text,
			Profile = dialog and dialog.Profile,
			Timing = dialog and dialog.Timing,
			Active = if dialog then true else false,
		}
	end

	return state
end

local store = Rodux.Store.new(function(state, action)
	return DialogReducer(state, action)
end)

Sink:GetService("Dialogue"):Sync(function(sink)
	sink:Get("Render"):Connect(function(text, profile, timing)
		store:dispatch({
			type = "QueueDialog",
			Text = text,
			Profile = profile,
			Timing = timing,
		})
		if not store:getState().Active then
			store:dispatch({
				type = "NextDialog",
			})
		end
	end)
end)

return store