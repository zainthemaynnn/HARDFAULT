local ServerScriptService = game:GetService("ServerScriptService")
local Loadout = ServerScriptService.Loadout

local PlayerData = require(script.Parent.PlayerData)

local DEFAULT_LOADOUT = require(Loadout.Droid)

local Characters = {}

Characters.Slots = {
	[1] = {
		Loadout = require(Loadout.Shift),
		Assigned = nil,
	},
	[2] = {
		Loadout = require(Loadout.Warp),
		Assigned = nil,
	},
	[3] = {
		Loadout = nil,
		Assigned = nil,
	},
	[4] = {
		Loadout = nil,
		Assigned = nil,
	},
}

PlayerData.PlayerAdded:Connect(function(pdata: any)
	for _, slot in pairs(Characters.Slots) do
		if slot.Assigned == nil then
			pdata:SetLoadout(slot.Loadout or DEFAULT_LOADOUT)
			slot.Assigned = pdata
			break
		end
	end
end)

return Characters