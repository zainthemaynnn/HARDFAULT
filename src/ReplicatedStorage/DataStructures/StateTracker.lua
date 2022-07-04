--[[
	*	hooks onto a table of values. you can listen for changes.
	*	inefficient? yes. fun? yes.
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Signal = require(ReplicatedStorage.Packages.Signal)

local StateTracker = {}
function StateTracker:__index(key)
	return self._Values[key] or StateTracker[key]
end

function StateTracker.new(baseTable)
	-- setting metatable afterwards so that __newindex doesn't screw with me
	local self = {}
	self._Values = {}
	self._OnChangedEvents = {}

	setmetatable(self, StateTracker)
	for k, v in pairs(baseTable) do
		self[k] = v
	end
	return self
end

function StateTracker:__newindex(key, value)
	local original = self._Values[key]
	self._Values[key] = value
	if original == nil then
		-- new
		self._OnChangedEvents[key] = Signal.new()
	elseif value == nil then
		-- delete
		self._OnChangedEvents[key]:Destroy()
		self._OnChangedEvents[key] = nil
	else
		-- update
		self._OnChangedEvents[key]:Fire(value)
	end
end

function StateTracker:Listen(key, listener)
	-- hook on to changes in one of the values
	local event = self._OnChangedEvents[key]
	if not event then
		error(("Value '%s' does not exist."):format(key), 2)
	end
	return event:Connect(listener)
end

return StateTracker