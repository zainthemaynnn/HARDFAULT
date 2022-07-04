local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sink = require(ReplicatedStorage.Sink)

local Lobbies = {}
Lobbies.MemStore = MemoryStoreService:GetSortedMap("Lobbies")

function Lobbies:Create(host: Player, maxSize: number, auth: string?)
	return pcall(function()
		self.Memstore:SetAsync(
			tostring(host.UserId),
			{
				Host = host,
				MaxSize = maxSize,
				Players = {host},
				Auth = auth,
			},
			600
		)
	end)
end

function Lobbies:Remove(host: Player)
	return pcall(function() self.MemStore:RemoveAsync(tostring(host.UserId)) end)
end

function Lobbies:Join(plr: Player, host: Player, auth: string?)
	return pcall(function()
		self.MemStore:UpdateAsync(
			tostring(host.UserId),
			function(lobby)
				if auth == lobby.Auth and #lobby.Players < lobby.MaxSize then
					table.insert(lobby.Players, plr)
				end
				return lobby
			end)
	end)
end

function Lobbies:Boot(host: Player, plr: Player)
	return pcall(function()
		self.MemStore:UpdateAsync(
			tostring(host.UserId),
			function(lobby)
				for i, p in pairs(lobby.Players) do
					if p.UserId == plr.UserId then
						table.remove(lobby.Players, i)
						break
					end
				end
				return lobby
			end)
	end)
end

function Lobbies:GetRange(n: number, lbound: number, rbound: number)
	return pcall(function()
		local lobbies = self.MemStore:GetRangeAsync(n, lbound, rbound)
		for _, lobby in pairs(lobbies) do
			lobby.Auth = nil
		end
		return lobbies
	end)
end

-- be careful with the refresh rate of this thing. could cause a lot of requests.
function Lobbies:GetFamiliar(plr: Player)
	local lobbies = {}
	for _, friend in pairs(Players:GetFriendsOnline(plr.UserId)) do
		if friend.GameId == game.JobId then
			local lobby = pcall(function()
				return self.MemStore:GetAsync(tostring(friend.VisitorId))
			end)
			table.insert(lobbies, lobby)
			lobby.Auth = nil
		end
	end
	return lobbies
end

Sink:CreateService("Lobbies")

local sink = Sink:Relay(
	"Lobbies",
	"Lobbies",
	{
		"Create",
		"Remove",
		"Join",
		"Boot",
		"GetRange",
		"GetFamiliar",
	}
)

sink["Create"]:Reply(function(...) return Lobbies:Create(...) end)
sink["Remove"]:Reply(function(...) return Lobbies:Remove(...) end)
sink["Join"]:Reply(function(...) return Lobbies:Join(...) end)
sink["Boot"]:Reply(function(...) return Lobbies:Boot(...) end)
sink["GetRange"]:Reply(function(...) return Lobbies:GetRange(...) end)
sink["GetFamiliar"]:Reply(function(_, ...) return Lobbies:GetFamiliar(...) end)

return Lobbies