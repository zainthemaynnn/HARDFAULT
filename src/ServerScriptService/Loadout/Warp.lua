local CharUtil = require(script.Parent.CharUtil)

local Warp = {}

Warp.HumDesc = (function()
	local humDesc = Instance.new("HumanoidDescription")
	CharUtil.applySkinTone(humDesc, BrickColor.new("Buttermilk").Color)
	humDesc.HairAccessory = CharUtil.Hair.BlackBrooding
	humDesc.Face = CharUtil.Face.Bruh
	humDesc.Shirt = CharUtil.Shirt.Lab
	humDesc.Pants = CharUtil.Pants.Lab
	return humDesc
end)()

function Warp:Description(): HumanoidDescription
	return Warp.HumDesc
end

return Warp