local ServerScriptService = game:GetService("ServerScriptService")
local Pathing = require(ServerScriptService.AI.Pathing)

local task = {}

local SUCCESS, FAIL, RUNNING = 1,2,3

function task.run(obj)
	local Blackboard = obj.Blackboard
	local plr, dist = Pathing.closestPlayer(obj.Model.PrimaryPart.Position, true)
	Blackboard.Target = plr
	Blackboard.TargetDistance = dist
	if obj.PreferredRange then
		Blackboard.InPreferredRange = plr and dist <= obj.PreferredRange
	end
	if Blackboard.Seeking and Blackboard.InPreferredRange ~= false then
		Blackboard.Seeking = false
		obj.RigMover:Stop()
	end
	return if plr then SUCCESS else FAIL
end
return task
