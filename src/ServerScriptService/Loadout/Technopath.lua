local ServerStorage = game:GetService("ServerStorage")
local Character = require(script.Parent)
local CharUtil = require(script.Parent.CharUtil)

local humDesc = Instance.new("HumanoidDescription")
CharUtil.applySkinTone(humDesc, BrickColor.new("Wheat").Color)
humDesc.Torso = CharUtil.Torso.Woman
humDesc.HairAccessory = CharUtil.Hair.GreyElegantPonytail
humDesc.Face = CharUtil.Face.Unimpressed
humDesc.Shirt = CharUtil.Shirt.Lab
humDesc.Pants = CharUtil.Pants.Lab

local Shifter = Character.new(humDesc, {
	ServerStorage.Accessories.Visor:Clone()
})

return Shifter