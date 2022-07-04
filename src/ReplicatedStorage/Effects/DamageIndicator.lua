local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local DamageIndicator = {}
DamageIndicator.__index = DamageIndicator

local INDICATOR = (function()
	local indicator = Instance.new("TextLabel")
	indicator.Font = Enum.Font.Code
	indicator.BackgroundTransparency = 1
	indicator.TextSize = 24
	local stroke = Instance.new("UIStroke", indicator)
	stroke.Thickness = 1
	stroke.Color = BrickColor.new("Really black").Color
	return indicator
end)()
local CAMERA = workspace.CurrentCamera
local SCREEN_GUI = Instance.new("ScreenGui", Players.LocalPlayer.PlayerGui)
SCREEN_GUI.Name = "DamageIndicators"
SCREEN_GUI.IgnoreGuiInset = true
local RNG = Random.new()

function DamageIndicator.new(amount: number, mult: number): any
	local self = setmetatable({}, DamageIndicator)
	self.Label = INDICATOR:Clone()
	self.Label.Text = tostring(amount)
	self.Label.TextColor3 =
		if amount < 0 then BrickColor.new("Bright green").Color -- heal
		elseif amount == 0 then BrickColor.new("Bright red").Color -- no dmg
		elseif mult < 1 then BrickColor.new("Dark stone grey").Color -- some dmg
		elseif mult == 1 then BrickColor.new("Institutional white").Color -- full dmg
		else BrickColor.new("Bright yellow").Color -- extra dmg
	return self
end

function DamageIndicator:Spawn(pos: Vector3, magnitude: number?, duration: number?)
	magnitude = magnitude or 16
	duration = duration or 0.5

	local screenPos = CAMERA:WorldToViewportPoint(pos)
	self.Label.Position = UDim2.fromOffset(screenPos.X, screenPos.Y)
	self.Label.Visible = true
	self.Label.Parent = SCREEN_GUI
	local tw = TweenService:Create(
		self.Label,
		TweenInfo.new(duration),
		{
			Position = self.Label.Position + UDim2.fromOffset(
				RNG:NextNumber()*magnitude, RNG:NextNumber()*magnitude
			),
		}
	)
	tw:Play()
	tw.Completed:Connect(function()
		self.Label:Destroy()
	end)
end

return DamageIndicator