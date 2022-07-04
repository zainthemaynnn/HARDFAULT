-- it's that simple! (TM)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Sink = require(ReplicatedStorage.Sink)

local Time = {}

Time.Speed = 1.0
Time.SpeedChanged = Signal.new()

function Time:SetSpeed(speed: number)
	self.Speed = speed
	self.SpeedChanged:Fire(self.Speed)
end

function Time:Adjusted(time: number): number
	return time / self.Speed
end

_G.time = function(t) return Time:Adjusted(t) end

if RunService:IsServer() then
	Time.Sink = Sink:CreateService(
		"Time",
		{
			"Set",
		}
	)

	Time.SpeedChanged:Connect(function(speed: number)
		Time.Sink["Set"]:FireAllClients(speed)
	end)

	task.delay(_G.time(_G.time(1.0)), function() end)

elseif RunService:IsClient() then
	Sink:GetService("Time"):Sync(function(sink: any)
		sink:Get("Set"):Connect(function(speed: number)
			Time:SetSpeed(speed)
		end)
	end)
end

return Time