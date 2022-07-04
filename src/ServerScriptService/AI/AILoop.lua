local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local EntityBlackboard = require(script.Parent.EntityBlackboard)
local Signal = require(ReplicatedStorage.Packages.Signal)

local FP_STEP = 2
local FP_QUICKSTEP = 1
local TICK_UPDATE_RATE = 1.0

local AILoop = {}
AILoop.Stepped = Signal.new()
AILoop.QuickStepped = Signal.new()
AILoop.TickRateUpdated = Signal.new()
AILoop.TickRateSecs = 0

local i = 0
local t, ticks = 0, 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	ticks += 1

	if t > TICK_UPDATE_RATE then
		AILoop.TickRateSecs = ticks/t
		AILoop.TickRateUpdated:Fire(AILoop.TickRateSecs)
		t, ticks = 0, 0
	end

	i += 1
	if i % FP_STEP == 0 then
		AILoop.Stepped:Fire()
	end
	if i % FP_QUICKSTEP == 0 then
		AILoop.QuickStepped:Fire()
	end
end)

local Connection = {}
Connection.__index = Connection

function AILoop.join(entity: any, tree: any)
	local self = setmetatable({}, Connection)
	self.Handler = function() tree:run(entity) end
	self._Internal = AILoop.Stepped:Connect(self.Handler)
	return self
end

function Connection:Start()
	if self._Internal then return end
	self._Internal = AILoop.Stepped:Connect(self.Handler)
end

function Connection:Stop()
	if self._Internal then
		self._Internal:Disconnect()
		self._Internal = nil
	end
end

function Connection:Disconnect()
	self:Stop()
end

AILoop.Blackboard = EntityBlackboard

return AILoop