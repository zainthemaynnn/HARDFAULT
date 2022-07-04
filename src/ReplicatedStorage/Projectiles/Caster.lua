-- FastCast on steroids. remember, steroids are bad, kids.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FastCast = require(ReplicatedStorage.Packages.FastCast)
local HitReg = require(ReplicatedStorage.HitReg)
local Signal = require(ReplicatedStorage.Packages.Signal)
local VecTools = require(ReplicatedStorage.Util.VecTools)

local Caster = {}
Caster.__index = Caster

function Caster.updatePosition(
	_: any,
	origin: Vector3,
	dir: Vector3,
	dist: number,
	_: Vector3,
	projectile: Part
)
	if not projectile then return end
	projectile.Position = origin + dir * dist
end

-- cast:Terminate() doesn't work inside LengthChanged events, according to the last 30 mins.
-- this is the next best thing. well, actually, literally the same thing.
-- I'm never touching that function again though.
function Caster._terminateNoCheck(cast: any)
	if not cast.StateInfo or not cast.RayInfo then return end
	cast.StateInfo.DistanceCovered = cast.RayInfo.MaxDistance
end

function Caster._terminateRoot(rootCast: any)
	Caster._terminateNoCheck(rootCast)
	for _, aux in pairs(rootCast.ChildCasts) do
		Caster._terminateNoCheck(aux)
	end
end

function Caster.terminate(cast: any)
	-- terminating an auxiliary cast terminates the entire group
	Caster._terminateRoot(cast.ParentCast or cast)
end

function Caster.disposeCast(cast: any)
	Caster.trySetTrailEnabled(cast, false)
	local projectile = cast.RayInfo.CosmeticBulletObject
	if cast.Parriable then
		projectile.BrickColor = cast.OgColor
	end
	if cast._PartCache then
		cast._PartCache:ReturnPart(projectile)
	else
		cast.RayInfo.CosmeticBulletObject:Destroy()
	end
end

-- prevent trails from being shown when getting and returning parts to part caches
-- ideally, this would belong in some kind of custom partcache wrapper object
-- unfortunately I'm not that civilized
function Caster.trySetTrailEnabled(cast: any, enabled: boolean)
	local projectile = cast.RayInfo.CosmeticBulletObject
	if not projectile then return end
	local trail = projectile:FindFirstChildWhichIsA("Trail")
	if trail then trail.Enabled = enabled end
end

function Caster:Ricochet(
	cast: any,
	result: RaycastResult,
	speed: number?,
	behavior: any,
	parriable: boolean?
)
	local vel = cast:GetVelocity()
	self:Fire(
		result.Position,
		vel - 2 * vel:Dot(result.Normal) * result.Normal,
		speed or vel.Magnitude,
		behavior,
		parriable
	)
end

function Caster.new(): any
	local self = setmetatable({}, Caster)
	self._Inner = FastCast.new()

	-- suppresses events from auxiliary casts
	local function suppressAux(inSig, outSig)
		inSig:Connect(function(cast, ...)
			if cast.ParentCast ~= nil then return end
			outSig:Fire(cast, ...)
		end)
	end

	-- the LengthChanged and CastTerminating events of auxiliary casts are ignored
	-- the event we want to keep is RayHit
	-- essentially, the cast updates as one but uses hit detection with multiple
	self.LengthChanged = Signal.new()
	self._LengthChangedSuppressor = suppressAux(self._Inner.LengthChanged, self.LengthChanged)
	self.LengthChanged:Connect(Caster.updatePosition)

	self.CastTerminating = Signal.new()
	self._CastTerminatingSuppressor = suppressAux(self._Inner.CastTerminating, self.CastTerminating)
	self.CastTerminating:Connect(function(cast) Caster.disposeCast(cast) end)

	self.RayHit = Signal.new()
	self._Inner.RayHit:Connect(function(cast: any, result: RaycastResult, ...)
		cast.Subject = HitReg:TryGet(result.Instance)
		self.RayHit:Fire(cast, result, ...)
	end)

	return self
end

function Caster.newBehavior()
	return FastCast.newBehavior()
end

function Caster.stdBehavior(collisionGroup: string, partcache: any?)
	return (function()
		local behavior = FastCast.newBehavior()
		behavior.RaycastParams = RaycastParams.new()
		behavior.RaycastParams.CollisionGroup = collisionGroup
		behavior.CosmeticBulletProvider = partcache
		return behavior
	end)()
end

function Caster:Fire(
	pos0: Vector3,
	dir: Vector3,
	speed: number,
	behavior: any,
	parriable: boolean?
)
	parriable = parriable or false

	local cast = self._Inner:Fire(pos0, dir, speed, behavior)
	cast.ParentCast = nil
	cast.ChildCasts = {}
	cast.Parriable = parriable
	if cast.Parriable then
		local projectile = cast.RayInfo.CosmeticBulletObject
		cast.OgColor = projectile.BrickColor
		projectile.BrickColor = BrickColor.new("Royal purple")
	end
	Caster.trySetTrailEnabled(cast, true)
	cast._PartCache = behavior.CosmeticBulletProvider
	return cast
end

-- runs a group cast to simulate larger projectiles
--
-- the primary cast will be fired from the origin,
-- this governs LengthChanged and CastTerminating events
-- it's also the one that gets returned, so put your user data in it
--
-- auxiliary casts are fired from displacements defined in `aux`
-- relative to the origin of the primary cast
-- these things can trigger RayHit
--
-- in total, you will get `#aux+1` casts
-- calling Caster.terminate(cast) on any cast will terminate the entire group
-- also, you can get the primary cast from auxiliary casts with `cast.ParentCast`
--
-- FastCast can render hundreds at a time pretty well
-- so if it gets slow, it's probably some garbage that I wrote, not FastCast
function Caster:FireGroup(
	pos0: Vector3,
	dir: Vector3,
	speed: number,
	behavior: any,
	aux: {Vector3}
)
	local primary = self:Fire(pos0, dir, speed, behavior)

	local cf = CFrame.lookAt(pos0, pos0 + dir)
	-- auxiliary casts shouldn't render the projectile
	local pcache = behavior.CosmeticBulletProvider
	behavior.CosmeticBulletProvider = nil
	for _, point in aux do
		local auxCast = self:Fire(cf:PointToWorldSpace(point), dir, speed, behavior)
		auxCast.ParentCast = primary
		table.insert(primary.ChildCasts, auxCast)
	end
	behavior.CosmeticBulletProvider = pcache

	return primary
end

-- almost every projectile in the game is a circle
-- this uses a circular group cast
function Caster:FireWithRadius(
	pos0: Vector3,
	dir: Vector3,
	speed: number,
	behavior: any,
	rad: number
)
	local points = VecTools.circle(math.floor(rad)*4)
	for i=1,#points do points[i] *= rad end
	local cast = self:FireGroup(pos0, dir, speed, behavior, points)
	cast.Radius = rad
	return cast
end

function Caster:Destroy()
	self._LengthChangedSuppressor:Disconnect()
	self.LengthChanged:DisconnectAll()
	self._CastTerminatingSuppressor:Disconnect()
	self.CastTerminating:DisconnectAll()
	self._Inner:Destroy()
end

return Caster