local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Sink = require(ReplicatedStorage.Sink)

Sink:CreateService("Journal")

local Journal = {}
Journal.Sink = Sink:Relay(
	"Journal",
	"Main",
	{
		"Create",
		"Populate",
	}
)
Journal.ENTRIES_PER_PLAYER = 100

Journal.Sink.Create:Connect(function(player, text)
	
end)

return Journal