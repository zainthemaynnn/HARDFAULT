local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CEnum = require(ReplicatedStorage.CEnum)
local Door = require(script.Door)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Sink = require(ReplicatedStorage.Sink)
local Timeline = require(script.Parent.Timeline)
local Quadtree = require(script.Quadtree)
local Zone = require(ReplicatedStorage.Packages.Zone)

local Room = {}
Room.__index = Room

local CamSink = Sink:CreateService("Camera", {
	"TopDown",
	"Follow",
}):Relay()

Room.SinkService = Sink:CreateService("Room", {
	"LightingOn",
	"LightingOff",
	"Boss",
	"BossHealth",
	"BossDied",
})

function Room.new(model: Model, timeline: (Room) -> ()): Room
	local self = setmetatable({}, Room)

	self.Name = model.Name
	self.Model = model
	self.Entered = false
	self.TimePassed = 0
	self.Timeline = Timeline.parseRbx(self, model.Timeline)
	self.UserTimeline = timeline
	local view = self.Model:FindFirstChild("View")
	self.View = view and view.CFrame
	self.Sink = self.SinkService:Relay(self.Model)
	self.Rng = Random.new()

	self.Players = {}
	self.Enemies = {}
	self.EnemyCount = 0
	self.Doors = {}
	self.Active = false

	for _, door in pairs(self.Model.Doors:GetChildren()) do
		self.Doors[#self.Doors+1] = Door.new(door)
	end

	local pp = self.Model.PrimaryPart
	local cf, size = self.Model:GetBoundingBox()
	self.CFrame = pp.CFrame + Vector3.new(0, pp.Size.Y/2, 0)
	self.Size = size

	self.Zone = Zone.fromRegion(cf, size)
	self.Lighting = self:GenerateLighting(BrickColor.new("Institutional white").Color, 16)

	self.EnemyAdded = Signal.new()
	self.EnemyDied = Signal.new()
	self.EnemiesCleared = Signal.new()
	self.Cleared = Signal.new()

	self.OnEntry = self.Zone.playerEntered:Connect(function(plr: Player)
		self.Sink["LightingOn"]:FireClient(plr, self.Lighting, false)
		table.insert(self.Players, plr)

		if #self.Players == 1 then
			self.Active = true
		end

		local pdata = PlayerData[plr.UserId]
		for enemy, _ in pairs(self.Enemies) do
			pdata:DiscoverEnemy(enemy)
		end

		if self.View ~= nil then
			CamSink["Follow"]:FireClient(plr, self.View.CFrame)
		else
			CamSink["TopDown"]:FireClient(plr, self.CFrame, self.Size, true)
		end

		task.wait(1.0)

		if not self.Entered then
			for _, door in pairs(self.Doors) do
				door:Lock(plr)
			end

			self.Entered = true
			self.UserTimeline(self)
			self.Cleared:Fire()
		end
	end)

	self.OnExit = self.Zone.playerExited:Connect(function(plr: Player)
		self.Sink["LightingOff"]:FireClient(plr, self.Lighting)
		if #self.Players == 0 then
			self.Active = false
		end
	end)

	self.OnClear = self.Cleared:Connect(function()
		for _, plr in pairs(self.Players) do
			for _, door in pairs(self.Doors) do
				door:Unlock(plr)
			end
		end
		task.delay(20.0, function() self:Clean() end)
	end)

	return self
end

-- treats the bounds of the room like a square and gets a point in 3D space on the surface of the floor
-- +X direction: -XVector; +Y direction: -ZVector
-- (that was a weird way to do it...)
function Room:PointFromUDim2(dim: UDim2): Vector3
	local res = self.CFrame:PointToWorldSpace(Vector3.new(
		-((dim.X.Scale - .5) * self.Size.X + dim.X.Offset),
		self.CFrame.Position.Y,
		-((dim.Y.Scale - .5) * self.Size.Z + dim.Y.Offset)
	))

	if not self.Zone:findPoint(res) then
		error("UDim2 out of bounds", 2)
	end
	return res
end

function Room:RandomPos(inset: number?, height: number?): Vector3
	inset = inset or 0.0
	height = height or 0.0
	local scaledInsetX, scaledInsetZ = inset/self.Size.X, inset/self.Size.Z
	return self:PointFromUDim2(
		UDim2.fromScale(
			self.Rng:NextNumber(scaledInsetX, 1-scaledInsetX), self.Rng:NextNumber(scaledInsetZ, 1-scaledInsetZ)
		)
	) + height * Vector3.yAxis
end

function Room:SpawnItem(item: any, pos: UDim2)
	item.Model.Parent = workspace
	item.Model:MoveTo(self:PointFromUDim2(pos))
end

function Room:RegisterEnemy(enemy: any)
	self.Enemies[enemy] = true
	self.EnemyCount += 1

	for _, plr in pairs(self.Players) do
		-- this wait isn't really needed during the game
		-- it's only an issue if they load directly into the room
		-- with a fair amount of lag
		-- which is exactly what happens during testing
		local pdata = PlayerData[plr.UserId] or PlayerData.PlayerAdded:Wait()
		pdata:DiscoverEnemy(enemy)
	end

	enemy.HpModule.Died:Connect(function()
		self.Enemies[enemy] = false
		self.EnemyCount -= 1
		self.EnemyDied:Fire(self.EnemyCount)
		if self.EnemyCount == 0 then
			self.EnemiesCleared:Fire()
		end
	end)

	if enemy.IsBoss then
		self.Sink["Boss"]:FireAllClients(enemy.Name)
		enemy.HpModule.Damaged:Connect(function()
			self.Sink["BossHealth"]:FireAllClients(enemy.HpModule:Percentage())
		end)
		enemy.HpModule.Died:Connect(function()
			self.Sink["BossDied"]:FireAllClients()
		end)
	end

	self.EnemyAdded:Fire(enemy)
end

function Room:GenerateLighting(color: Color3, range: number): SurfaceLight
	local lighting = Instance.new("SurfaceLight")
	lighting.Face = Enum.NormalId.Top
	lighting.Angle = 90.0
	lighting.Shadows = false
	lighting.Color = color
	lighting.Brightness = 1
	lighting.Range = range
	lighting.Enabled = false
	lighting.Parent = self.Model.PrimaryPart
	return lighting
end

function Room:ContinuousSpawn()
	for _=1, #self.Timeline.Events do
		self.Timeline:Advance()
		self.EnemiesCleared:Wait()
	end
end

function Room:Clean()
	for enemy, _ in pairs(self.Enemies) do
		enemy:Destroy()
	end
end

function Room:Destroy()
	self.OnEntry:Disconnect()
	self.OnExit:Disconnect()
	for k, _ in pairs(self) do
		self[k] = nil
	end
end

export type Room = typeof(Room.new(Instance.new("Model"), {}))

return Room