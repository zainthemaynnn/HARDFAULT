local CharUtil = require(script.Parent.CharUtil)

local Shift = {}

Shift.HumDesc = (function()
	local humDesc = Instance.new("HumanoidDescription")
	CharUtil.applySkinTone(humDesc, BrickColor.new("Medium brown").Color)
	humDesc.HairAccessory = CharUtil.Hair.BlackCombed
	humDesc.Face = CharUtil.Face.Neutral
	humDesc.Shirt = CharUtil.Shirt.Tux
	humDesc.Pants = CharUtil.Pants.Tux
	return humDesc
end)()

function Shift:Description(): HumanoidDescription
	return Shift.HumDesc
end

return Shift