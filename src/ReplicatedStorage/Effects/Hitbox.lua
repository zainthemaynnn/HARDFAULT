local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaycastHitbox = require(ReplicatedStorage.Packages.RaycastHitbox)

local Hitbox = {}

Hitbox.RcParams = (function()
	local params = RaycastParams.new()
	params.CollisionGroup = "NPC"
	return params
end)()

function Hitbox.create(part: Part)
	local hitbox = RaycastHitbox.new(part)
	hitbox.SignalType = 1
	hitbox.RaycastParams = Hitbox.RcParams
	return hitbox
end

function Hitbox.activate(hitbox, time: number?, handler: (hit: Part, hum: Humanoid) -> ())
	hitbox:HitStart(time)
	hitbox.OnHit:Connect(handler)
end

return Hitbox