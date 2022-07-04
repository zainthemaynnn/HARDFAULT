-- this is a higher level interface for ReplicatedStoage.Time
-- switching time is pretty expensive, especially when it comes to casts
-- it's generally smarter to change at intervals instead of constantly
-- however, if there's not that much happening I suppose it could
-- use time shifts are your own discretion
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Table = require(ReplicatedStorage.Util.Tabl)
local Time = require(ReplicatedStorage.Time)

local StageClock = {}
StageClock.__index = StageClock

function StageClock.new(len: number, seq: NumberSequence)
	local self = setmetatable({}, StageClock)
	self.Length = len
	self.Sequence = seq
	self._Current = self.Sequence[1]
	self._Update = nil
	return self
end

function StageClock:_WrappedIdx(i: number): number
	return if i > #self.Sequence then i % #self.Sequence
end

function StageClock:Start()
	local t = 0
	self._Update = RunService.Heartbeat:Connect(function(dt: number)
		t = (t + dt/len) % 1
		local kp = self.Sequence[
			Table.bsearch(
				self.Sequence,
				function(i: number)
					if t < self.Sequence[i].Time then
						return 1
					elseif t >= self.Sequence[i+1].Time then
						return 2
					else
						return 0
					end
				end
			)
		]
		if self._Current ~= kp then
			self._Current = kp
			Time:SetSpeed(kp.Vaue)
		end
	end)
end

function StageClock.sine(len: number, min: number, max: number, fidelity: number?)
	fidelity = fidelity or 60
	local keypoints = {}
	local n = fidelity+1
	for i=0, n do
		keypoints[i] = NumberSequenceKeypoint.new(i/n, min+math.sin(math.pi*i/n)^2*(max-min))
	end
	return StageClock.new(len, NumberSequence.new(keypoints))
end

function StageClock.steps(len: number, min: number, max: number, steps: number?)
	steps = steps or 2
	local keypoints = {}
	local n = steps+2
	for i=0, n-1 do
		keypoints[i] = NumberSequenceKeypoint.new(i/n, min+(i/(n-1))*(max-min))
	end
	keypoints[#keypoints+1] = keypoints[#keypoints]
	return StageClock.new(len, NumberSequence.new(keypoints))
end

return StageClock