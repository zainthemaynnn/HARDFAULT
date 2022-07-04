local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local Sink = require(ReplicatedStorage.Sink)

local function BestiaryReducer(state, action)
	state = state or {
		Enemies = {},
		EnemiesTotal = 0,
		Selected = 1,
		Active = false,
	}

	if action.type == "Initialize" then
		return {
			Enemies = action.Discovered,
			EnemiesTotal = action.EnemiesTotal,
			Selected = state.Selected,
			Active = state.Active,
		}

	elseif action.type == "UpdateEnemies" then
		state.Enemies[action.Index] = action.Discovered
		return {
			Enemies = state.Enemies,
			EnemiesTotal = state.EnemiesTotal,
			Selected = state.Selected,
			Active = state.Active,
		}

	elseif action.type == "Select" then
		return {
			Enemies = state.Enemies,
			EnemiesTotal = state.EnemiesTotal,
			Selected = action.Selected,
			Active = state.Active,
		}

	elseif action.type == "Activate" then
		return {
			Enemies = state.Enemies,
			EnemiesTotal = state.EnemiesTotal,
			Selected = state.Selected,
			Active = action.Active,
		}
	end

	return state
end

local store = Rodux.Store.new(function(state, action)
	return BestiaryReducer(state, action)
end)

Sink:GetService("Player"):Sync(function(sink)
	sink:Get("LoadBestiary"):Connect(function(discovered: {any}, total: number)
		store:dispatch({
			type = "Initialize",
			Discovered = discovered,
			EnemiesTotal = total,
		})
	end)

	sink:Get("EnemyDiscovered"):Connect(function(index: number, discovered: any)
		store:dispatch({
			type = "UpdateEnemies",
			Index = index,
			Discovered = discovered,
		})
	end)
end)

return store