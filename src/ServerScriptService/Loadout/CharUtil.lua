local CharUtil = {}

CharUtil.Hair = {
	BrownCharmer = 376548738,
	BlackCombed = 5163619571,
	BlackBrooding = 13655562,
	BlackSpiked = 3814450142,
	BlackLowPonytail = 7486439370,
	GreyElegantPonytail = 5944981473,
}

CharUtil.Face = {
	Neutral = 8560971,
	HayFever = 180660043,
	Unimpressed = 7075469,
	Nervous = 23219981,
	Bruh = 15637848,
	Wink = 7506135,
}

CharUtil.Package = {
	Woman = 282,
}

CharUtil.Shirt = {
	Agent = 7769085689,
	Tux = 1997169394,
	Lab = 2240854871,
}

CharUtil.Pants = {
	Agent = 7769116504,
	Tux = 1997178515,
	Lab = 2240665732,
}

CharUtil.Accessory = {
	CrimsonShades = 68358795,
	BlackStyledBeard = 7177948497,
	ClassicFedora = 1029025,
	Respirator = 6719179191,
}

function CharUtil.applySkinTone(desc, color)
	for _, k in pairs({
		"HeadColor", "LeftArmColor", "LeftLegColor",
		"RightArmColor", "RightLegColor", "TorsoColor",
	}) do
		desc[k] = color
	end
end

return CharUtil