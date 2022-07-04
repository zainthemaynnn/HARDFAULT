local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sink = require(ReplicatedStorage.Sink)

local GameManager = {}
GameManager.ResetRequests = 0
GameManager.Ready = {}
GameManager.Sink = Sink:CreateService("GameManager", {
	"Start",
	"Reset",
}):Relay()

function GameManager:Start()
	-- body
end

function GameManager:RequestReset(plr: Player)
	self.ResetRequests += 1
	self.Ready[plr] = true
end

function GameManager:TryReset()
	if self.ResetRequests >= #Players:GetPlayers() then
		self:Reset()
	end
end

function GameManager:Reset()
	-- TODO
end

Players.PlayerRemoving:Connect(function(plr: Player)
	if GameManager.Ready[plr] == true then
		GameManager.Ready[plr] = false
		GameManager.ResetRequests -= 1
		GameManager:TryReset()
	end
end)

GameManager.Sink:Get("Reset"):Connect(function(...) GameManager:RequestReset(...) end)

return GameManager