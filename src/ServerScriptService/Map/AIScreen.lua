local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local AIScreen = {}
AIScreen.__index = AIScreen

local BOB_RATE_SECS = 0.5
local BOB_DISPLACEMENT_PERCENT = .05

AIScreen.BaseImage = (function()
	local img = Instance.new("Part")
	img.Transparency = 1
	img.Anchored = true
	img.CanCollide = false
	local decal = Instance.new("Decal", img)
	decal.Texture = "rbxassetid://618893698"
	decal.Color3 = BrickColor.new("Electric blue").Color
	return img
end)()

function AIScreen.new(surface: BasePart)
	local self = setmetatable({}, AIScreen)
	self.Surface = surface
	self.Image = self.BaseImage:Clone()
	self.Cf0 = surface.CFrame:ToWorldSpace(
		CFrame.new(Vector3.new(0, 0, -surface.Size.Z/2)) * CFrame.Angles(0, 0, math.rad(180))
	)
	self.Image.CFrame = self.Cf0
	self.Image.Size = Vector3.new()
	self.Image.Parent = workspace
	self._TrackLoop = nil
	return self
end

function AIScreen:Track(fn: () -> (Vector3?))
	local t = 0
	self._TrackLoop = RunService.Heartbeat:Connect(function(dt: number)
		local target = fn()
		t += _G.time(dt)
		local cf0 = self.Cf0 + self.Cf0:VectorToWorldSpace(
			Vector3.yAxis * self.Image.Size.Y * BOB_DISPLACEMENT_PERCENT * if t/BOB_RATE_SECS % 2 < 1.0 then 1 else -1
		)

		if target == nil then
			self.Image.CFrame = cf0
		else
			target = cf0:PointToObjectSpace(target)
			local dir = (target * Vector3.new(1, 0, 1)).Unit
			local a = math.acos(-Vector3.zAxis:Dot(dir))
			self.Image.CFrame = cf0 + cf0:VectorToWorldSpace(Vector3.xAxis * math.sin(a) * if dir.X < 0 then 1 else -1 * (self.Surface.Size.X/2 - self.Image.Size.X/2))
		end
	end)
end

function AIScreen:Untrack()
	if self._TrackLoop then self._TrackLoop:Disconnect() end
end

function AIScreen:Show()
	local dim = math.min(self.Surface.Size.X, self.Surface.Size.Y)
	local tw = TweenService:Create(self.Image, TweenInfo.new(_G.time(0.25)), { Size = Vector3.new(dim, dim, 0) })
	tw:Play()
	return tw
end

function AIScreen:Shut()
	local tw = TweenService:Create(self.Image, TweenInfo.new(_G.time(0.25)), { Size = self.Image.Size * Vector3.new(1, 0, 1) })
	tw:Play()
	return tw
end

function AIScreen:Destroy()
	self:Untrack()
	self.Image:Destroy()
end

return AIScreen