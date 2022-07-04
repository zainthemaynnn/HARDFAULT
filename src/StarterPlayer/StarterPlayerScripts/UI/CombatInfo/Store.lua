local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rodux = require(ReplicatedStorage.Packages.Rodux)
local SFX = require(ReplicatedStorage.Effects.SFX)
local Sink = require(ReplicatedStorage.Sink)
local WeaponProvider = require(ReplicatedStorage.WeaponProvider)

local HIT_SOUNDS = {
	"Flesh 1",
	"Flesh 2",
	"Flesh 3",
	"Flesh 4",
	"Flesh 5",
}

local function HPReducer(state, action)
	state = state or {
		MaxHP = 100,
		HP = 100,
		Items = {
			[1] = nil,
			[2] = nil,
		},
		Selected = 1,
		Boss = nil,
		MousePosition = Vector3.new(),
	}

	if action.type == "TakeDamage" then
		return {
			MaxHP = state.MaxHP,
			HP = math.max(state.HP - action.Amount, 0),
			Items = state.Items,
			Selected = state.Selected,
			Boss = state.Boss,
			MousePosition = state.MousePosition,
		}
	elseif action.type == "NewItem" then
		state.Items[action.Slot] = action.Item
		return {
			MaxHP = state.MaxHP,
			HP = state.HP,
			Items = state.Items,
			Selected = state.Selected,
			Boss = state.Boss,
			MousePosition = state.MousePosition,
		}
	elseif action.type == "NewSlot" then
		return {
			MaxHP = state.MaxHP,
			HP = state.HP,
			Items = state.Items,
			Selected = action.Slot,
			Boss = state.Boss,
			MousePosition = state.MousePosition,
		}
	elseif action.type == "Used" or action.Type == "Reloaded" then
		return {
			MaxHP = state.MaxHP,
			HP = state.HP,
			Items = state.Items,
			Selected = state.Selected,
			Boss = state.Boss,
			MousePosition = state.MousePosition,
		}
	elseif action.type == "MouseUpdate" then
		return {
			MaxHP = state.MaxHP,
			HP = state.HP,
			Items = state.Items,
			Selected = state.Selected,
			Boss = state.Boss,
			MousePosition = action.Position,
		}
	elseif action.type == "Boss" then
		return {
			MaxHP = state.MaxHP,
			HP = state.HP,
			Items = state.Items,
			Selected = state.Selected,
			Boss = action.Boss,
			MousePosition = state.MousePosition,
		}
	elseif action.type == "BossHealth" then
		return {
			MaxHP = state.MaxHP,
			HP = state.HP,
			Items = state.Items,
			Selected = state.Selected,
			Boss = state.Boss and {
				Name = state.Boss.Name,
				Hp = action.Hp,
			},
			MousePosition = state.MousePosition,
		}
	end

	return state
end

local store = Rodux.Store.new(function(state, action)
	return HPReducer(state, action)
end)

Sink:GetService("Player"):Sync(function(sink: any, plr: Player)
	if plr ~= Players.LocalPlayer then return end

	local Rng = Random.new()

	sink:Get("NewItem"):Connect(function(itemId: string, slot: number)
		store:dispatch({
			type = "NewItem",
			Item = WeaponProvider[itemId],
			Slot = slot,
		})
	end)

	sink:Get("NewSlot"):Connect(function(slot: number)
		store:dispatch({
			type = "NewSlot",
			Slot = slot,
		})
	end)

	sink:Get("TakeDamage"):Connect(function(amount: number)
		SFX:Play(HIT_SOUNDS[Rng:NextInteger(1, #HIT_SOUNDS)])
		store:dispatch({
			type = "TakeDamage",
			Amount = amount,
		})
	end)
end)

Sink:GetService("Room"):Sync(function(sink: any, plr: Player)
	sink:Get("Boss"):Connect(function(name: string)
		store:dispatch({
			type = "Boss",
			Boss = {
				Name = name,
				Hp = 1,
			}
		})
	end)

	sink:Get("BossHealth"):Connect(function(hpPercent: number)
		store:dispatch({
			type = "BossHealth",
			Hp = hpPercent,
		})
	end)

	sink:Get("BossDied"):Connect(function()
		store:dispatch({
			type = "Boss",
			Boss = nil,
		})
	end)
end)

return store