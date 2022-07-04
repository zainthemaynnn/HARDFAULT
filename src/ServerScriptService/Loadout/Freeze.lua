local Character = require(script.Parent)
local CharUtil = require(script.Parent.CharUtil)

local humDesc = Instance.new("HumanoidDescription")
CharUtil.applySkinTone(humDesc, BrickColor.new("Dark orange").Color)
humDesc.HairAccessory = CharUtil.Hair.BlackSpiked
humDesc.Face = CharUtil.Face.Nervous
humDesc.Shirt = CharUtil.Shirt.Lab
humDesc.Pants = CharUtil.Pants.Lab
humDesc.FaceAccessory = CharUtil.Accessory.BlackStyledBeard

local Shifter = Character.new(humDesc, {})

return Shifter