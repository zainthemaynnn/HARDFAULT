local Character = require(script.Parent)
local CharUtil = require(script.Parent.CharUtil)

local humDesc = Instance.new("HumanoidDescription")
CharUtil.applySkinTone(humDesc, BrickColor.new("Really black").Color)
humDesc.Torso = CharUtil.Torso.Woman
humDesc.HairAccessory = CharUtil.Hair.BlackLowPonytail
humDesc.Face = CharUtil.Face.HayFever
humDesc.Shirt = CharUtil.Shirt.Agent
humDesc.Pants = CharUtil.Pants.Agent
humDesc.FaceAccessory = CharUtil.Accessory.ClassicFedora

local Shifter = Character.new(humDesc, {})

return Shifter