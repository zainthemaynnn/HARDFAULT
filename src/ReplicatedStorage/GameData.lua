local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StateTracker = require(ReplicatedStorage.DataStructures.StateTracker)
return StateTracker.new({
	Speed = 1.0,
	Area = "Red",
	Stage = "001",
})