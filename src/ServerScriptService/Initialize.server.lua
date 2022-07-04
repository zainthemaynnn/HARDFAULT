local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local Tweens = game:GetService("TweenService")
local Characters = require(ServerScriptService.Game.Characters)
local PlayerData = require(script.Parent.Game.PlayerData)
local GameCache = require(script.Parent.Game.GameCache)
local CEnum = require(ReplicatedStorage.CEnum)
local SFX = require(ReplicatedStorage.Effects.SFX)
local w = require(ServerScriptService.Loadout.Shift)
local Sink = require(ReplicatedStorage.Sink)
local Time = require(ReplicatedStorage.Time)

--[[for _, s in pairs(ServerScriptService.AI.Enemy:GetChildren()) do
	require(s)
end--]]

for _, s in pairs(ServerScriptService.Loadout.Weapon:GetChildren()) do
	require(s)
end

--Lighting.Ambient = Color3.new(0,0,0)
Lighting.Brightness = 0

GameCache:LoadMap()

SFX:Init({
	["Music"] = {
		["Title"] = 9044728299,
		["World 1"] = 9044564552,
		["World 1:1"] = 1836855968,
		["Facility 1"] = 1843005255,
		["Lab 1"] = 9038283343,
		["Chrono 1"] = 1837087812,
		["Caves 1"] = 1845991627,
		["Sim 1"] = 1837441450,
		["Factory 1"] = 1837969120,
		["Factory 1 boss"] = 1847799916,
		["Factory 2"] = 1845992084,
		["Sewers 1"] = 9038335001,
		["Shadow 1"] = 1845012088,
		["Shadow"] = 9042781325,
		["Otherworld 2"] = 1836550662,
		["Smilebyte theme"] = 9038252619,
	},
	["SFX"] = {
		["Text"] = 515150941,--179235828,
		["Soda crackle"] = 6911756259,
		["Slurrrp, AHH"] = 6911756959,

		["Pistol 1"] = 8482911117,
		["SMG 1"] = 5948204445,
		["Shotgun 1"] = 134188543,
		["Sniper 1"] = 6001411181,
		["Reload 1"] = 138084889,
		["Clip empty"] = 240785604,

		["Laser pulse 1"] = 6603571443,
		["Laser pulse 2"] = 9119783432,
		["Heavy laser pulse"] = 180204650,
		["Rocket pulse"] = 5904790530,
		["Light laser"] = 9071076896,

		["Pressure blast"] = 9117892240,
		--["Whomp"] = 9119862009,
		["Meow"] = 8855537449,

		["Vine boom?"] = 9125401684,

		["Flesh 1"] = 6978731806,
		["Flesh 2"] = 6978731977,
		["Flesh 3"] = 6978732129,
		["Flesh 4"] = 6978732312,
		["Flesh 5"] = 6978732459,
		["Metal 1"] = 2303101209,

		["Boom"] = 6296105178,
		["Button"] = 7884774051,
		["Pop"] = 3073639118,
		["Ninja swish"] = 9120297624,
		["Whirring"] = 9117127008,
		["Pew"] = 5261013273,

		["Death 1"] = 1542642349,
		["Death 2"] = 1491069651,
		["Death 3"] = 4340605706,
		["Death 4"] = 2542613889,
		["Heartbeat"] = 176651233,

		["Slow alarm"] = 8107634493,
		["Creepy alarm"] = 7136355744,

		["Zap"] = 4086010159,
		["Zapping"] = 9114235852,
		["Bass"] = 9119856136,
		["Buzzer"] = 9113085321,
		["CrystalShot"] = 5226834046,

		["Blink"] = 289556450,
		["Blink DBZ"] = 5909720414,
		["Blink Terraria"] = 5518430240,
		["Blink VVVVVVV"] = 164320294,

		["FieldMini"] = 9114465643,
		["FieldBig"] = 9113455338,
		["Whomp"] = 7667174465,
		["1SecChargeBoom"] = 9118772469,
		["LightBuzz"] = 9114246999,
		["Screech 1"] = 9125475148,
		["Pelo"] = 2542613889,

		["Ambient gunfire"] = 2620294650,
		["Ambient lab"] = 9112881419,

		["Robodeath"] = 9119816268,
		["TeleSpawn"] = 4562690876,
		["VoidSpawn"] = 8232515665,
		["WhooshTP"] = 5830950642,
	},
})
SFX:SetVolume("Pew", 0.005)
SFX:SetVolume("CrystalShot", 0.05)
SFX:SetVolume("Boom", 0.05)

local junk = Instance.new("Folder", workspace)
junk.Name = "Junk"

PlayerData.PlayerAdded:Connect(function(pdata)
	local player = pdata.Player
	local holder = Instance.new("Part")
	holder.Name = "AttachmentHolder_" .. player.Name
	holder.Anchored = true
	holder.CanCollide = false
	holder.Size = Vector3.new()
	holder.Parent = junk

	local mouseAtt = Instance.new("Attachment", holder)

	player.CharacterAdded:Connect(function(char: Model)
		-- physics attachments
		local root = Instance.new("Attachment", char.PrimaryPart)
		root.Name = "RootAttachment"

		-- cosmetic attachments
		local reatt = Instance.new("Attachment", char.Head)
		reatt.Position = Vector3.new(0.2, 0.25, -0.6)
		reatt.Name = "RightEyeAttachment"

		local leatt = Instance.new("Attachment", char.Head)
		leatt.Position = Vector3.new(0.2, 0.25, -0.6)
		leatt.Name = "LeftEyeAttachment"

		for _, p in pairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(p, "Player")
			end
		end

		local h = char:FindFirstChildWhichIsA("Humanoid")
		h.BreakJointsOnDeath = false
	end)
end)

local Signal = require(ReplicatedStorage.Packages.Signal)

local TICK_UPDATE_RATE = 1.0

_G.TickRateUpdated = Signal.new()
_G.TickRateSecs = 0

local i = 0
local t, ticks = 0, 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	ticks += 1

	if t > TICK_UPDATE_RATE then
		_G.TickRateSecs = ticks/t
		_G.TickRateUpdated:Fire(_G.TickRateSecs)
		t, ticks = 0, 0
	end
end)

local MAX = 20
local chosen = Random.new():NextInteger(1, MAX)
for i = 1, MAX do
	local e = Instance.new("RemoteEvent", ReplicatedStorage.Remotes.Roulette)
	if i == chosen then
		e.OnServerEvent:Connect(function(player)
			player:Kick("Winner B)))")
		end)
	else
		e.OnServerEvent:Connect(function(player)
			player:Kick("Lose B(((")
		end)
	end
end
