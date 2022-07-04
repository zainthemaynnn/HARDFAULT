local EntityBlackboard = {}
EntityBlackboard.__index = EntityBlackboard

function EntityBlackboard:__call(...)
	return self.new(...)
end

function tableJoinMut(t1: table, t2: table)
	for k, v in pairs(t2) do
		t1[k] = v
	end
end

function EntityBlackboard.new(blackboard: {string: any})
	return setmetatable(blackboard, EntityBlackboard)
end

function EntityBlackboard.withTracking(blackboard: {string: any})
	tableJoinMut(blackboard, {
		Target = nil,
		TargetDistance = math.huge,
		InPreferredRange = false,
		Seeking = false,
	})
	return EntityBlackboard.new(blackboard)
end

function EntityBlackboard.withPathing(blackboard: {string: any})
	tableJoinMut(blackboard, {
		CanComputePath = true,
		PathReady = false,
		Waypoints = nil,
	})
	return EntityBlackboard.withTracking(blackboard)
end

function EntityBlackboard:StartCooldown(key: string, delay: number, switchTo: boolean?)
	if switchTo == nil then switchTo = true end
	self[key] = not switchTo
	task.delay(delay, function() self[key] = switchTo end)
end

EntityBlackboard.SUCCESS = 1
EntityBlackboard.FAIL = 2
EntityBlackboard.RUNNING = 3

return EntityBlackboard