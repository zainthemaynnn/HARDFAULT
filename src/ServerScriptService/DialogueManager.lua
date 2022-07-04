local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Sink = require(ReplicatedStorage.Sink)
local Shift = require(ServerScriptService.Loadout.Shift)
local Warp = require(ServerScriptService.Loadout.Warp)

local DialogueManager = {}

local PROFILE_FOLDER = ServerStorage:FindFirstChild("DialogueManager")

DialogueManager.Sink = Sink:CreateService("Dialogue", {
	"Render",
	"Cut",
}):Relay()

function DialogueManager._createR15Profile(humDesc: HumanoidDescription)
	local profile = ServerStorage.R15:Clone()
	local humanoid = profile:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then return end
	profile.Parent = PROFILE_FOLDER
	humanoid:ApplyDescription(humDesc)
	return profile
end

DialogueManager.Profiles = {
	Black = DialogueManager._createR15Profile(Shift:Description()),
	White = DialogueManager._createR15Profile(Warp:Description()),
	AI = PROFILE_FOLDER.SmileByte,
}

function DialogueManager:Say(name: string, text: string, timing: number?, players: {Player}?)
	timing = timing or #text * 1.1 / 30 + 1.0
	local profile = self:_GetOrReplicateProfile(name)
	if players then
		for _, plr in pairs(players) do
			self.Sink["Render"]:FireClient(plr, text, profile, timing)
		end
	else
		self.Sink["Render"]:FireAllClients(text, profile, timing)
	end
	return timing
end

function DialogueManager:Cut()
	-- will implement if I need to
end

function DialogueManager:_GetOrReplicateProfile(name: string)
	local profile = self.Profiles[name]
	if not profile then return error(("Profile does not exist: `%s`"):format(name)) end
	if not profile:IsDescendantOf(workspace) then
		profile.Parent = workspace
		profile:MoveTo(Vector3.new(8888, 0, 8888))
	end
	return profile
end

return DialogueManager