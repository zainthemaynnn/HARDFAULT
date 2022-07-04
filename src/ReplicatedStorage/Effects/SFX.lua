--!strict
-- Q: why the heck aren't you using the actual SoundService?
-- A: replication is botched with that thing. apparently they need to be under workspace.
--		go figure.
local RunService = game:GetService("RunService")
local SoundServiceReal = game:GetService("SoundService")

local SoundService do
	if RunService:IsServer() then
		SoundService = Instance.new("Folder", workspace)
		SoundService.Name = "SoundService"
	else
		SoundService = workspace:WaitForChild("SoundService")
	end
end

local SFX = {}

function SFX:Init(assets)
	for group, audios in pairs(assets) do
		SFX:AddGroup(group)
		for audio, id in pairs(audios) do
			SFX:Add(audio, id, group)
		end
	end
end

function SFX:AddGroup(name: string)
	local group = Instance.new("SoundGroup", SoundService)
	group.Name = name
end

function SFX:Add(name: string, id: number, soundGroup: string?)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. tostring(id)
	if soundGroup then
		sound.SoundGroup = SoundService[soundGroup]
	end
	sound.PlayOnRemove = true
	sound.Parent = SoundService
end

function SFX:Play(name: string, duration: number?, looped: boolean?)
	local sound = SoundService:FindFirstChild(name)
	if sound then
		if not sound.IsLoaded then sound.Loaded:Wait() end
		sound.PlaybackSpeed = if duration then sound.TimeLength / duration else 1.0
		sound.Looped = looped or false
		-- before you call this stupid
		-- https://twitter.com/DogutsuneRBX/status/932003997321515009
		if RunService:IsServer() then
			sound:Play()
		else
			SoundServiceReal:PlayLocalSound(sound)
		end
	else
		warn("Could not find audio asset: " .. name)
	end
end

function SFX:Stop(name: string)
	local sound = SoundService:FindFirstChild(name)
	if sound then
		sound:Stop()
	else
		warn("Could not find audio asset: " .. name)
	end
end

function SFX:SetVolume(name: string, volume: number)
	local sound = SoundService:FindFirstChild(name)
	if sound then
		sound.Volume = volume
	else
		warn("Could not find audio asset: " .. name)
	end
end

return SFX