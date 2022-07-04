local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local Pathing = {}
local rng = Random.new()
local npcRaycastParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "NPCProjectile"
	return params
end)()

function Pathing.closestPlayer(origin: Vector3, needsLineOfSight: boolean?): Player
	if needsLineOfSight == nil then needsLineOfSight = true end
	local player = nil
	local dist = math.huge
	for _, p in pairs(Players:GetPlayers()) do
		local char = p.Character
		if not char or needsLineOfSight and not Pathing.directLineOfSight(origin, char.PrimaryPart.Position, char) then continue end
		local pdist = (char.PrimaryPart.Position - origin).Magnitude
		if pdist < dist and pdist < math.huge then
			dist = pdist
			player = p
		end
	end
	return player, dist
end

function Pathing.randomPlayer()
	local plrs = Players:GetPlayers()
	return plrs[rng:NextInt(1, #plrs)]
end

function Pathing.directLineOfSight(pos0: Vector3, pos1: Vector3, target: Instance)
	local res = workspace:Raycast(pos0, pos1 - pos0, npcRaycastParams)
	return res and res.Instance:FindFirstAncestor(target.Name)
end

-- all agents in the game pretty much go like this
function Pathing:CreatePath(radius: number, height: number): Path
	return PathfindingService:CreatePath({
		AgentHeight = height,
		AgentRadius = radius,
		AgentCanJump = false,
	})
end

function Pathing:Compute(path: Path, pos0: Vector3, pos1: Vector3): Path?
	local success, err = pcall(function() path:ComputeAsync(pos0, pos1) end)
	return if success and path.Status == Enum.PathStatus.Success then path else warn(path.Status, err)
end

return Pathing