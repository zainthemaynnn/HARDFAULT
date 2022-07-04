local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local ObjStaller = {}
ObjStaller.__index = ObjStaller

local DEFAULT_TIMEOUT = 15.0

-- like waitforchild, but wraps with lua object
function ObjStaller.new(src: Instance, handler: (Instance) -> ...any, timeout: number?)
	local self = setmetatable({}, ObjStaller)
	self.ChildAdded = Signal.new()
	self._Source = src
	self._Syncing = {}
	self._Timeout = timeout or DEFAULT_TIMEOUT
	self._Children = {}
	for _, child in pairs(self._Source:GetChildren()) do
		local wrapped = handler(child)
		self._Children[child.Name] = wrapped
		self.ChildAdded:Fire(wrapped)
	end
	self._OnChildAdded = self._Source.ChildAdded:Connect(function(inst: Instance)
		local id = inst.Name
		local wrapped = handler(inst)
		self._Children[id] = wrapped
		local s = self._Syncing[id]
		if s then
			s:Fire(wrapped)
			self._Syncing[id] = nil
		end
		self.ChildAdded:Fire(wrapped)
	end)
	return self
end

function ObjStaller:GetChildren(): {any}
	return self._Children
end

function ObjStaller:WaitFor(id: string)
	if self._Children[id] then
		return self._Children[id]
	else
		local s = Signal.new()
		self._Syncing[id] = s
		task.delay(self._Timeout, function()
			if not self._Syncing[id] then return end
			warn(("Instance %s under %s may yield indefinitely"):format(id, self._Source.Name))
		end)
		return s:Wait()
	end
end

function ObjStaller:Destroy()
	self._OnChildAdded:Disconnect()
	for _, signal in pairs(self._Syncing) do
		signal:DisconnectAll()
	end
end

return ObjStaller