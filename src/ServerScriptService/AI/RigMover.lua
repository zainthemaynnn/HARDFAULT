-- move NPCs with body movers
-- does pathfinding
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)

local PATHMAP_OFFSET = Vector3.new(1e3, 1e3, 1e3)
local PATH_ATTEMPTS = 1

local RigMover = {}
RigMover.__index = RigMover

function RigMover.new(model: Model, speed: number, size: number)
	local self = setmetatable({}, RigMover)
	self.Model = model
	self.Speed = speed
	self.Rng = Random.new()

	self._AttachmentHolder = Instance.new("Part", workspace.Junk)
	self._AttachmentHolder.Anchored = true

	local pp = self.Model.PrimaryPart
	self._PrimaryAttachment = Instance.new("Attachment", pp)

	self._BodyVelocity = (function()
		local bv = Instance.new("VectorForce", pp)
		bv.RelativeTo = Enum.ActuatorRelativeTo.World
		bv.Attachment0 = self._PrimaryAttachment
		bv.Force = Vector3.new()
		return bv
	end)()

	self._AlignOrientation = (function()
		local ao = Instance.new("AlignOrientation", pp)
		ao.RigidityEnabled = true
		ao.Attachment0 = self._PrimaryAttachment
		ao.Attachment1 = Instance.new("Attachment", self._AttachmentHolder)
		ao.Attachment1.CFrame = model.PrimaryPart.CFrame.Rotation
		return ao
	end)()

	self.Path = PathfindingService:CreatePath({
		AgentRadius = math.max(size.X, size.Z),
		AgentHeight = size.Y,
		AgentCanJump = false,
		WaypointSpacing = 4.0,
	})

	self.MoveBegan = Signal.new()
	self.MoveEnded = Signal.new()
	-- sometimes the rig tends to get a call to move in the same frame that it was supposed to stop
	-- obviously an issue. such is the world of RunService.Heartbeat. this band-aid stops the worst of it though.
	-- if you ever wonder why your staggers don't work, it's this.
	self._Locked = false
	self._FollowTarget = nil
	self._AtSetpoint = true
	self._RcParams = RaycastParams.new()
	self._RcParams.FilterDescendantsInstances = {self.Model}

	return self
end

-- canonize Y for 2D plane. should generally use this for all external positions in case of height difference.
function RigMover:ToLevel(pos: Vector3): Vector3
	return Vector3.new(pos.X, self.Model.PrimaryPart.Position.Y, pos.Z)
end

function RigMover:LookAt(pos: Vector3)
	pos = self:ToLevel(pos)
	local att1 = self._AlignOrientation.Attachment1
	att1.CFrame = CFrame.lookAt(self.Model.PrimaryPart.Position, pos)
end

function RigMover:Align(fn: () -> Vector3?)
	self:Unalign()
	self._FollowTarget = RunService.Heartbeat:Connect(function()
		local pos = fn()
		if pos then
			self:LookAt(pos)
		end
	end)
end

function RigMover:Unalign()
	if self._FollowTarget then
		self._FollowTarget:Disconnect()
		self._FollowTarget = nil
	end
end

function vecMin(a: Vector3, mag: number)
	if a.Magnitude > mag then
		return a.Unit * mag
	else
		return a
	end
end

function RigMover:_MoveToInternal(pos: Vector3, speed: number?, stop: boolean?): boolean
	speed = speed or self.Speed
	stop = stop or true
	pos = self:ToLevel(pos)

	self._AtSetpoint = (pos - self.Model.PrimaryPart.Position).Magnitude <= 1.0
	if self._AtSetpoint then
		self.MoveEnded:Fire(false)
		return false
	end

	self:_StopInternal(false)

	self._AtSetpoint = false

	self._CheckPos = RunService.Heartbeat:Connect(function()
		if not self.Model.PrimaryPart then return self._CheckPos:Disconnect() end
		pos = self:ToLevel(pos)

		local mass = self.Model.PrimaryPart.AssemblyMass
		local curVelocity = vecMin(self.Model.PrimaryPart.AssemblyLinearVelocity, 30.0)
		local curPos = self.Model.PrimaryPart.Position
		local dir = pos - curPos
		-- F = m*(v-u)/t
		self._BodyVelocity.Force = mass * (dir.Unit*speed - curVelocity) / (1/math.max(_G.TickRateSecs, 1))

		self._AtSetpoint = dir.Magnitude <= 1.0
		if self._AtSetpoint then
			self:_StopInternal(stop)
			self.MoveEnded:Fire(false)
		end
	end)
	return true
end

function RigMover:MoveTo(pos: Vector3, speed: number?, stop: boolean?)
	if self._Locked then return end
	if not self._AtSetpoint then
		self.MoveEnded:Fire(true)
	end
	self.MoveBegan:Fire()

	self:_MoveToInternal(pos, speed, stop)
end

function RigMover:AccelerateTo(pos: Vector3, acceleration: number, targetSpeed: number?, stop: boolean?)
	if self._Locked then return end
	targetSpeed = targetSpeed or self.Speed

	if not self._AtSetpoint then
		self.MoveEnded:Fire(true)
	end
	self.MoveBegan:Fire()

	local conn do
		local t = 0
		conn = RunService.Stepped:Connect(function(dt: number)
			t += dt
			if not self:_MoveToInternal(pos, math.min(acceleration * t^2, targetSpeed), stop) then return conn:Disconnect() end
		end)
	end
end

function RigMover:FollowPath(waypoints: {PathWaypoint}, speed: number?)
	if self._Locked or #waypoints < 1 then return end
	if not self._AtSetpoint then
		self.MoveEnded:Fire(true)
	end
	self.MoveBegan:Fire()

	task.spawn(function()
		for i=2,#waypoints-1 do
			local w = waypoints[i]
			self:_MoveToInternal(w.Position-PATHMAP_OFFSET, speed, true)
			local interrupted = self.MoveEnded:Wait()
			if interrupted then return end
		end
		self:_MoveToInternal(waypoints[#waypoints].Position-PATHMAP_OFFSET, speed, false)
	end)
end

function RigMover:_StopInternal(stop: boolean?)
	if stop == nil then stop = true end
	if self._CheckPos then self._CheckPos:Disconnect() end
	if stop then
		self._Locked = true
		if not self.Model.PrimaryPart then return end
		local mass = self.Model.PrimaryPart.AssemblyMass
		local curVelocity = vecMin(self.Model.PrimaryPart.AssemblyLinearVelocity, 30.0)
		-- F = m*(v-u)/t
		self._BodyVelocity.Force = mass * (-curVelocity) / (1/_G.TickRateSecs)
		local conn do
			conn = RunService.Stepped:Connect(function()
				conn:Disconnect()
				self._BodyVelocity.Force = Vector3.new()
				self._Locked = false
			end)
		end
	end
end

function RigMover:Stop(stop: boolean?)
	self:_StopInternal(stop)
	self.MoveEnded:Fire(true)
end

function RigMover:Raycast(dir: Vector3)
	return workspace:Raycast(self.Model.PrimaryPart.Position, dir, self._RcParams)
end

function RigMover:Downcast(): RaycastResult?
	return self:Raycast(-Vector3.yAxis * 99)
end

function RigMover:Randomcast(dist: number): (RaycastResult?, Vector3)
	local dir = self.Model.PrimaryPart.CFrame:VectorToWorldSpace(
		(self.Rng:NextUnitVector() * Vector3.new(1, 0, 1)).Unit * dist
	)
	return workspace:Raycast(self.Model.PrimaryPart.Position, dir, self._RcParams), dir
end

function RigMover:RandomPos(dist: number): (Vector3, Vector3)
	return self.Model.PrimaryPart.CFrame:PointToWorldSpace(
		(self.Rng:NextUnitVector() * Vector3.new(1, 0, 1)).Unit * dist
	)
end

function RigMover:TryComputePath(target: Vector3): {PathWaypoint}?
	local success = false
	for _=1,PATH_ATTEMPTS do
		self.Path:ComputeAsync(self.Model.PrimaryPart.Position+PATHMAP_OFFSET, target+PATHMAP_OFFSET)
		if self.Path.Status == Enum.PathStatus.Success then
			success = true
			break
		end
	end
	return success and self.Path:GetWaypoints()
end

function RigMover:Destroy()
	self:Unalign()
	self:_StopInternal()
	self.MoveBegan:DisconnectAll()
	self.MoveEnded:DisconnectAll()
	self._AttachmentHolder:Destroy()
	self._BodyVelocity:Destroy()
	self._AlignOrientation:Destroy()
end

return RigMover