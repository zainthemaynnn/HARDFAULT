local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Tweens = game:GetService("TweenService")

local CEnum = require(ReplicatedStorage.CEnum)
local CombatInfo = require(script.Parent:WaitForChild("UI"):WaitForChild("CombatInfo"):WaitForChild("Store"))
local Sink = require(ReplicatedStorage.Sink)
local VecTools = require(ReplicatedStorage.Util.VecTools)

-- small offset for camera height when automatically calculated
local CAM_DIST_OFFSET = 80.0
local CAM_ANGLE_OFFSET = math.rad(-15)

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()

-- no idea if this bug was fixed, but I'm keeping it here
local camera: Camera = workspace.CurrentCamera
if not camera.CameraSubject then
	repeat
		RunService.RenderStepped:Wait()
	until camera.CameraSubject
end
camera.CameraType = Enum.CameraType.Scriptable
local mouse = player:GetMouse()

local camPart = Instance.new("Part")
camPart.Transparency = 1
camPart.CanCollide = false
camPart.Name = "CamPart"

local att = Instance.new("Attachment", camPart)

local ap = Instance.new("AlignPosition", camPart)
ap.Attachment0 = att
ap.Mode = Enum.PositionAlignmentMode.OneAttachment
local ao = Instance.new("AlignOrientation", camPart)
ao.Attachment0 = att
ao.Mode = Enum.OrientationAlignmentMode.OneAttachment

camPart.Parent = workspace

-- https://devforum.roblox.com/t/forcing-a-certain-aspect-ratio-for-the-camera-on-all-clients/390845/2
function getHorizontalFov(cam: Camera): number
	local z = cam.NearPlaneZ
	local viewSize = cam.ViewportSize

	local r0, r1 =
		cam:ViewportPointToRay(0, viewSize.Y/2, z),
		cam:ViewportPointToRay(1, viewSize.Y/2, z)

	return math.deg(math.acos(r0.Direction.Unit:Dot(r1.Direction.Unit)))
end

-- https://youtu.be/fIu_8b2n8ZM
-- https://youtu.be/27vT-NWuw0M

RunService:BindToRenderStep("FaceMouse2D", Enum.RenderPriority.Character.Value, function()
	local origin = char.PrimaryPart.Position
	local ray = camera:ScreenPointToRay(mouse.X, mouse.Y)
	-- the ray will hit backwards when pointing above the camera's Y, so reverse the X and Z components
	if ray.Direction.Y > 0 then ray = Ray.new(ray.Origin, ray.Direction * Vector3.new(-1, 1, -1)) end
	local plane = {
		Origin = origin,
		Normal = CEnum.Direction.Up,
	}

	local viewProjection = ray.Direction:Dot(plane.Normal)
	if viewProjection == 0 then return end

	local referenceVector = plane.Origin - ray.Origin
	local parameter = (referenceVector:Dot(plane.Normal)) / viewProjection
	local mousePos = ray.Origin + ray.Direction * parameter
	char.PrimaryPart.CFrame = CFrame.lookAt(origin, mousePos)

	CombatInfo:dispatch({
		type = "MouseUpdate",
		Position = mousePos,
	})

	local cf = CFrame.lookAt(VecTools.rotate(Vector3.yAxis * CAM_DIST_OFFSET, CAM_ANGLE_OFFSET, Vector3.xAxis), Vector3.new())
	ap.Position = cf.Position + char.PrimaryPart.Position
	ao.CFrame = cf
end)

RunService:BindToRenderStep("CamChase", Enum.RenderPriority.Camera.Value, function()
	camera.CFrame = camPart.CFrame
end)
