--[[
	mini networking module. jank. works damn well though.
	usage:
	```
	-- server
	local bruhService = Sink:CreateService("Bruh", {
		"Say bruh", -- name of remotes
	})
	local sink = bruhService:Relay(5) -- extra initializer arguments in parentheses

	sink["Say bruh"]:FireAllClients("bruh")

	-- client
	Sink:Sync("Bruh", function(sink: any, delay: number)
		-- on the client we need to use `Get` in case it hasn't replicated yet
		sink:Get("Say bruh"):Connect(function(msg: string)
			task.delay(delay, function() print("bruh") end)
		end)
	)
	```
	note the omission of `OnClientEvent` and `OnServerEvent`
	because I always forget to write them and they're annoying.
--]]

local HTTP = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TestService = game:GetService("TestService")

local ObjStaller = require(script.ObjStaller)
local Remote = require(script.Remote)

local SINK_REMOTE_FOLDER = "Sink Remotes"
local INIT_REMOTE_NAME = "_Initializer"
local REQUEST_INIT_PARAMS_REMOTE_NAME = "RequestInitParams"
local SYNC_REPORT_TIMEOUT_SECS = 15.0

local Sink = {}
Sink.__index = Sink

local function err404(serviceId: string)
	error(("No Sink service found with name `%s`."):format(serviceId))
end

if RunService:IsServer() then
	Sink._Services = {}

	Sink._ServiceContainer = Instance.new("Folder", ReplicatedStorage)
	Sink._ServiceContainer.Name = SINK_REMOTE_FOLDER

	Sink._InitParams = {}

	local Service = {}
	Service.__index = Service

	function Service.new(serviceId: string, blueprint: {string}): any
		local self = setmetatable({}, Service)
		self._Container = Instance.new("Folder", Sink._ServiceContainer)
		self.Name = serviceId
		self._Container.Name = serviceId
		self.Blueprint = blueprint
		return self
	end

	function Sink:GetService(serviceId: string): any?
		return self._Services[serviceId]
	end

	local rip = Instance.new("RemoteFunction", ReplicatedStorage)
	rip.Name = REQUEST_INIT_PARAMS_REMOTE_NAME
	rip.OnServerInvoke = function(_, folders)
		local params = {}
		for _, folder in pairs(folders) do
			params[folder] = Sink._InitParams[folder]
		end
		return params
	end

	local Relay = {}
	Relay.__index = Relay

	function Relay.new(service: any, ...: any): any
		local id = HTTP:GenerateGUID(false)
		local relay = setmetatable({}, Relay)
		relay._Container = Instance.new("Folder", service._Container)
		relay._Container.Name = id
		for _, signal in pairs(service.Blueprint) do
			relay[signal] = Remote.new(signal, relay._Container)
		end
		relay._Initializer = Remote.new(INIT_REMOTE_NAME, relay._Container)
		relay._Initializer:FireAllClients(...)
		Sink._InitParams[id] = table.pack(...)
		return relay
	end

	function Relay:Destroy()
		self._Container:Destroy()
	end

	function Relay:GetGUID(): string
		return self._Container.Name
	end

	function Sink:CreateService(serviceId: string, blueprint: {string}): any
		if self:GetService(serviceId) then return error(("Sink service `%s` already exists."):format(serviceId)) end
		local service = Service.new(serviceId, blueprint)
		self._Services[serviceId] = service
		return service
	end

	function Service:Relay(...: any): any
		local relay = Relay.new(self, ...)
		Sink._InitParams[relay:GetGUID()] = table.pack(...)
		return relay
	end

elseif RunService:IsClient() then
	Sink._Services = {}
	Sink._ServiceContainer = ReplicatedStorage:WaitForChild(SINK_REMOTE_FOLDER)
	local rip = ReplicatedStorage:WaitForChild(REQUEST_INIT_PARAMS_REMOTE_NAME)

	local Relay = {}
	Relay.__index = Relay

	function Relay.new(folder: Folder): any
		local self = setmetatable({}, Relay)
		self._Syncing = {}
		self._Container = folder
		self._ObjStaller = ObjStaller.new(self._Container, Remote.fromRBX)
		self._Binds = {}
		return self
	end

	function Relay:Get(name: string): any
		return self._ObjStaller:WaitFor(name)
	end

	function Relay:BindAll(obj: any)
		for _, remote in pairs(self._ObjStaller:GetChildren()) do
			if obj[remote.Name] ~= nil then
				remote:Connect(function(...) obj[remote.Name](obj, ...) end)
			end
		end
		self._ObjStaller.ChildAdded:Connect(function(remote: any)
			if obj[remote.Name] then
				remote:Connect(function(...) obj[remote.Name](obj, ...) end)
			end
		end)
	end

	function Relay:GetGUID(): string
		return self._Container.Name
	end

	function Relay:Destroy()
		self._ObjStaller:Destroy()
	end

	local Service = {}
	Service.__index = Service

	function Service.new(serviceContainer: Folder): any
		local self = setmetatable({}, Service)
		self._Container = serviceContainer
		self._Container.ChildRemoved:Connect(function(relayContainer)
			local s = self._Synced[relayContainer]
			if s then s:Destroy() end
		end)
		self._Synced = {}
		return self
	end

	function Service:Sync(handler: (any, ...any) -> ()): RBXScriptConnection
		local conn do
			conn = self._Container.ChildAdded:Connect(function(folder)
				local relay = Relay.new(folder)
				self._Synced[folder] = relay
				handler(relay, relay:Get(INIT_REMOTE_NAME):Wait())
			end)
		end

		local unsynced = {}
		for _, folder in pairs(self._Container:GetChildren()) do
			table.insert(unsynced, folder.Name)
		end
		local initParams = rip:InvokeServer(unsynced)
		for _, id in pairs(unsynced) do
			local folder = self._Container[id]
			local relay = Relay.new(folder)
			self._Synced[folder] = relay
			handler(relay, table.unpack(initParams[tostring(id)]))
		end

		return conn
	end

	Sink._ServiceObjStaller = ObjStaller.new(Sink._ServiceContainer, Service.new)

	function Sink:GetService(serviceId: string): any
		return self._ServiceObjStaller:WaitFor(serviceId)
	end

	-- often, I need to link models to lua objects
	-- the idea is that a group of sink connections can be used
	-- to put objects into a into a provider which is indexed by sink GUIDs
	-- and the model is named after the sink GUID
	-- although this function doesn't name the model
	function Sink.provider(scripts: {ModuleScript}, autoBind: boolean?): {string: any}
		autoBind = autoBind or false

		local self = {}
		local successes, total = 0, #scripts

		for _, s in pairs(scripts) do
			task.defer(function()
				local success, err = pcall(function()
					local cls = require(s)
					Sink:GetService(s.Name):Sync(function(sink, ...)
						local obj = cls.new(sink, ...)
						self[sink:GetGUID()] = obj
						if autoBind then
							sink:BindAll(obj)
						end
					end)
				end)
				if success then
					successes += 1
				else
					TestService:Error(err)
				end
			end)
		end

		task.delay(SYNC_REPORT_TIMEOUT_SECS, function()
			TestService:Warn(successes == total, ("Successfully synced %d/%d instances"):format(successes, total))
		end)

		return self
	end
end

return Sink