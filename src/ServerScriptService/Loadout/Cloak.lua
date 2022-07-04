local Character = require(script.Parent)
local CharUtil = require(script.Parent.CharUtil)

local humDesc = Instance.new("HumanoidDescription")
CharUtil.applySkinTone(humDesc, BrickColor.new("Really black").Color)
humDesc.HairAccessory = CharUtil.Hair.BlackCharmer
humDesc.Face = CharUtil.Face.HayFever
humDesc.Shirt = CharUtil.Shirt.Tux
humDesc.Pants = CharUtil.Pants.Tux
humDesc.FaceAccessory = CharUtil.Accessory.CrimsonShades

local Shifter = Character.new(humDesc, {})

return Shifter