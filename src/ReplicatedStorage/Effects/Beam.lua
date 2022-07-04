local TweenService = game:GetService("TweenService")

-- attachment holder
local gb = Instance.new("Part")
gb.Anchored = true
gb.Transparency = 1
gb.CanCollide = false

local Beam = {}
Beam.__index = Beam

function Beam.new(beam: Beam)
	local self = setmetatable({}, Beam)

	self._Beam = beam

	self._AttHolder = gb:Clone()
	self._AttHolder.Name = "Beam"
	self._AttHolder.Parent = workspace.Junk

	beam.Attachment0 = Instance.new("Attachment", self._AttHolder)
	beam.Attachment1 = Instance.new("Attachment", self._AttHolder)
	beam.FaceCamera = true

	self._Transparency = Instance.new("NumberValue", self._Beam)
	self._Transparency.Name = "Transparency"
	self._TransparencyLink = self._Transparency:GetPropertyChangedSignal("Value"):Connect(function()
		self._Beam.Transparency = NumberSequence.new(self._Transparency.Value)
	end)
	self._Transparency.Value = 0

	return self
end

function Beam:MoveTo(pos0: Vector3, pos1: Vector3)
	self._Beam.Attachment0.WorldPosition = pos0
	self._Beam.Attachment1.WorldPosition = pos1
end

function Beam:SetTransparency(transparency: number)
	self._Transparency.Value = transparency
end

function Beam:SetEnabled(on: boolean)
	self._Beam.Enabled = on
end

function Beam:Fade(transparency: number, tweenInfo: TweenInfo?)
	TweenService:Create(self._Transparency, tweenInfo or TweenInfo.new(), { Value = transparency }):Play()
end

function Beam:VisualRaycast(pos0: Vector3, dir: Vector3, castParams: RaycastParams): RaycastResult?
	local res = workspace:Raycast(pos0, dir * 100, castParams)
	if res then
		self:MoveTo(pos0, res.Position)
	else
		self:MoveTo(pos0, pos0 + dir * 100)
	end
	return res
end

function Beam:Clone()
	return Beam.new(self._Beam)
end

function Beam:Destroy()
	self._Beam:Destroy()
	self._AttHolder:Destroy()
	self._TransparencyLink:Disconnect()
end

return Beam