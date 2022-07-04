local ServerScriptService = game:GetService("ServerScriptService")

local Enemies = {}
for _, mod in pairs(ServerScriptService.AI.Enemy:GetChildren()) do
	pcall(function() Enemies[mod.Name] = require(mod) end)
end

local SpawnEvent = {}
SpawnEvent.__index = SpawnEvent

function SpawnEvent.new(room: any, spawns: {any})
	return function()
		if #spawns ~= 0 then
			for _, spawn in pairs(spawns) do
				local e = Enemies[spawn.Type]
				if not e then error(("unidentified enemy %s"):format(spawn.Type)) end
				local enemy = e.new(room)
				enemy:Spawn(spawn.CFrame, 1.0)
				room:RegisterEnemy(enemy)
				task.wait(1.0/4)
			end
		else
			task.delay(1.0, function() room.EnemiesCleared:Fire() end)
		end
	end
end

function SpawnEvent.parseRbx(room: any, folder: Folder)
	local spawns = {}
	for _, spawn in pairs(folder.Spawns:GetChildren()) do
		spawns[#spawns+1] = {
			Type = spawn.Type.Value,
			CFrame = spawn.CFrame.Value,
			Delay = spawn.Delay.Value,
		}
	end
	return SpawnEvent.new(room, spawns)
end

local Timeline = {}
Timeline.__index = Timeline

function Timeline.new(events: {any})
	local self = setmetatable({}, Timeline)
	self.Events = events
	self.Index = 1
	return self
end

function Timeline:Advance()
	if self.Index > #self.Events then return warn("timeline finished!") end
	self.Events[self.Index]()
	self:Goto(self.Index+1)
end

function Timeline:Repeat()
	self.Events[self.Index]()
end

function Timeline:Goto(idx: number)
	self.Index = idx
end

function Timeline.parseRbx(room: any, folder: Folder)
	local events = {}
	for _, event in pairs(folder:GetChildren()) do
		events[event.Index.Value] = SpawnEvent.parseRbx(room, event)
	end
	return Timeline.new(events)
end

return Timeline