local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local ASSIGN_REMOTE_KEY = "Assign"

local charUI = nil

local function buildRoactRoduxApp(name: string)
	local folder = script:FindFirstChild(name)
	if not folder then error(("no UI `%s`"):format(name), 2) end

	return Roact.createElement(RoactRodux.StoreProvider, {
		store = require(folder.Store),
	}, require(folder.Components))
end

for _, char in pairs(ReplicatedStorage.Remotes.Loadout:GetChildren()) do
	local assign = char:FindFirstChild(ASSIGN_REMOTE_KEY)
	if not assign then
		warn(("`%s` has no remote `%s`; skipping UI initialization"):format(char.Name, ASSIGN_REMOTE_KEY))
		continue
	end

	assign.OnClientEvent:Connect(function()
		if charUI then Roact.unmount(charUI) end
		charUI = Roact.mount(buildRoactRoduxApp(char.Name), Players.LocalPlayer.PlayerGui)
		print("mounted")
	end)
end

game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

-- Roact.mount(buildRoactRoduxApp("Title"), Players.LocalPlayer.PlayerGui)
-- print("mounted")
Roact.mount(buildRoactRoduxApp("Dialog"), Players.LocalPlayer.PlayerGui)
Roact.mount(buildRoactRoduxApp("CombatInfo"), Players.LocalPlayer.PlayerGui)
Roact.mount(buildRoactRoduxApp("Bestiary"), Players.LocalPlayer.PlayerGui)
Roact.mount(buildRoactRoduxApp("VFX"), Players.LocalPlayer.PlayerGui)
