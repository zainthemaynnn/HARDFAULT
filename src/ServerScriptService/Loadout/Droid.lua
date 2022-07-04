local CharUtil = require(script.Parent.CharUtil)

local Droid = {}

Droid.HumDesc = (function()
	local humDesc = Instance.new("HumanoidDescription")
	CharUtil.applySkinTone(humDesc, BrickColor.new("Dark stone grey").Color)
	return humDesc
end)()

function Droid:Description(): HumanoidDescription
	return Droid.HumDesc
end

return Droid