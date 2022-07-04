local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)

local Cooldown = {}
Cooldown.__index = Cooldown

function Cooldown.new(targetValue: boolean): any
	local self = setmetatable({}, Cooldown)
	self.T = 0
	self.Value = targetValue
	self.Began = Signal.new()
	self.Ended = Signal.new()
	self._Update = RunService.Heartbeat:Connect(function(dt: number)
		if self:Complete() then return end
		self.T = math.max(0, self.T - _G.time(dt))
		if self.T == 0 then
			self.Value = targetValue
			self.Ended:Fire()
		end
	end)
	return self
end

function Cooldown:Complete(): boolean
	return self.T == 0
end

function Cooldown:Reset(duration: number)
	if self:Complete() and duration ~= 0.0 then
		self.Value = not self.Value
		self.Began:Fire(duration)
	end
	self.T = duration
end

function Cooldown:Poll(duration: number): boolean
	local v = self.Value
	if self:Complete() then
		self:Reset(duration)
		return v
	else
		return v
	end
end

function Cooldown:__eq(v: any)
	return if typeof(v) == "boolean" then rawequal(self.Value, v) else rawequal(self, v)
end

function Cooldown:Destroy()
	self._Update:Disconnect()
end

return Cooldown