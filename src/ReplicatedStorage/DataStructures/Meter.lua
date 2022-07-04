--!strict
local Meter = {}
Meter.__index = Meter

-- meter from 0 to 1
function Meter.new(min: number?, max: number?, rate: number?, value: number?): Meter
	local self = setmetatable({}, Meter)
	self.Min = min or 0
	self.Max = max or 1
	self.Rate = rate or 0
	self.Value = value or self.Max
	return self
end

function Meter:Step(delta: number)
	self.Value = math.clamp(
		self.Value :: number + self.Rate :: number * delta, self.Min, self.Max
	)
end

local function getMeta(...)
	return Meter.new(...)
end

export type Meter = typeof(getMeta())

return Meter