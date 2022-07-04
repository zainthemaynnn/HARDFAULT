local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Remote = {}
Remote.__index = Remote

function Remote.fromRBX(remote: RemoteEvent)
	local self = setmetatable({}, Remote)
	self.Name = remote.Name
	self._RbxRemote = remote
	return self
end

if RunService:IsServer() then
	function Remote.new(name: string, location: Instance)
		local self = setmetatable({}, Remote)
		self.Name = name
		self._RbxRemote = Instance.new("RemoteEvent", location)
		self._RbxRemote.Name = name
		return self
	end

	function Remote:FireClient(p: Player, ...: any)
		self._RbxRemote:FireClient(p, ...)
	end

	function Remote:FireAllClients(...: any)
		self._RbxRemote:FireAllClients(...)
	end

	function Remote:FireAllClientsExcept(player: Player, ...: any)
		for _, p in pairs(Players:GetPlayers()) do
			if p.UserId ~= player.UserId then
				self:FireClient(p, ...)
			end
		end
	end

	function Remote:Connect(callback: (...any) -> ())
		return self._RbxRemote.OnServerEvent:Connect(callback)
	end

	function Remote:Reply(callback: (...any) -> any)
		return self:Connect(function(plr: Player, ...) self:FireClient(plr, callback(...)) end)
	end

	function Remote:ReplyAll(callback: (...any) -> any)
		return self:Connect(function(plr: Player, ...) self:FireAllClients(plr, callback(...)) end)
	end

	function Remote:Wait()
		return self._RbxRemote.OnServerEvent:Wait()
	end

	-- rate limiter
	function Remote:Drip(maxAttempts: number?, timeout: number?)
		maxAttempts = maxAttempts or 10
		timeout = timeout or 1

		local attempts do
			task.spawn(function()
				while self._RbxRemote do
					if attempts > 0 then
						attempts -= 1
					end
					task.wait(timeout)
				end
			end)
		end

		self._RbxRemote.OnServerEvent:Connect(function(player: Player)
			attempts += 1
			if attempts > maxAttempts then
				player:Kick("You are sending too many requests. Consider filing a bug report.")
			end
		end)

		return self
	end

elseif RunService:IsClient() then
	function Remote:FireServer(...: any)
		self._RbxRemote:FireServer(...)
	end

	function Remote:Connect(callback: (...any) -> ())
		return self._RbxRemote.OnClientEvent:Connect(callback)
	end

	function Remote:Reply(callback: (...any) -> any)
		return self:Connect(function(...) self:FireServer(callback(...)) end)
	end

	function Remote:Wait()
		return self._RbxRemote.OnClientEvent:Wait()
	end
end

return Remote