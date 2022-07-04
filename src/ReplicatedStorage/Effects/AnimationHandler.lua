--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Time = require(ReplicatedStorage.Time)

local AnimationHandler = {}
AnimationHandler.__index = AnimationHandler

function AnimationHandler.new(controller: Humanoid | AnimationController, animations: {Animation}): AnimationHandler
	local self = setmetatable({}, AnimationHandler)
	self.Tracks = {}
	self._Speed = Time.Speed

	local animator =
		controller:FindFirstChildWhichIsA("Animator")
		or Instance.new("Animator", controller)

	for _, anim: Animation in pairs(animations) do
		local track: AnimationTrack = animator:LoadAnimation(anim)
		self.Tracks[track.Name] = track
		if track.Name == "Idle" then
			track.Priority = Enum.AnimationPriority.Idle
		elseif track.Name == "Walk" or track.Name == "Run" then
			track.Priority = Enum.AnimationPriority.Movement
		end
	end

	if self.Tracks["Idle"] then
		self:Play("Idle")
	end

	Time.SpeedChanged:Connect(function(speed: number)
		for _, track in pairs(self.Tracks) do
			track:AdjustSpeed(1/self._Speed*speed)
		end
		self._Speed = speed
	end)

	return self
end

function AnimationHandler:GetTrack(name: string)
	local track = self.Tracks[name]
	return track or warn(("AnimationTrack `%s` not found."):format(name))
end

function AnimationHandler:Play(name: string, duration: number?)
	local track = self:GetTrack(name)
	track:AdjustSpeed(track.Length / (duration or track.Length))
	track:Play()
end

function AnimationHandler:PlayIfNotPlaying(name: string, duration: number?)
	local track = self:GetTrack(name)
	if track.IsPlaying then return end
	self:Play(name, duration)
end

function AnimationHandler:Stop(name: string, fade: number?)
	local track = self:GetTrack(name)
	track:Stop(fade or _G.time(0.5))
end

function AnimationHandler:AdjustSpeed(speed: number)
	for _, track in pairs(self.Tracks) do
		track:AdjustSpeed(speed)
	end
end

local function getMeta(...) return AnimationHandler.new(...) end

export type AnimationHandler = typeof(getMeta(Instance.new("AnimationController"), {}))

return AnimationHandler