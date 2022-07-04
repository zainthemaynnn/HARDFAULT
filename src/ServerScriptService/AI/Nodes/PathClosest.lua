local ServerScriptService = game:GetService("ServerScriptService")

local AILoop = require(ServerScriptService.AI.AILoop)
local Pathing = require(ServerScriptService.AI.Pathing)

-- ticks instead of seconds, since it's expensive
local PATH_COMPUTE_COOLDOWN_TICKS = 60

local taaask = {}

local SUCCESS, FAIL, RUNNING = 1,2,3

function taaask.run(obj)
	local Blackboard = obj.Blackboard
	if not Blackboard.PathReady then
		local target = Pathing.closestPlayer(obj.Model.PrimaryPart.Position, false)
		if not target then return FAIL end
		task.defer(function()
			Blackboard.Waypoints = obj.RigMover:TryComputePath(
				target.Character.PrimaryPart.Position
			)
			Blackboard.PathReady = true
			Blackboard:StartCooldown("CanComputePath", PATH_COMPUTE_COOLDOWN_TICKS / AILoop.TickRateSecs)
		end)
		return RUNNING
	else
		if Blackboard.Waypoints then
			Blackboard.PathReady = false
			Blackboard.Seeking = true
			obj.RigMover:FollowPath(Blackboard.Waypoints)
			return SUCCESS
		else
			return FAIL
		end
	end
end
return taaask
