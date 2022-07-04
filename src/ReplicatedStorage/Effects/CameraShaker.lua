local RunService = game:GetService("RunService")

local CameraShaker = {}
CameraShaker.__index = CameraShaker

CameraShaker.Camera = workspace.CurrentCamera
CameraShaker._Rng = Random.new()
CameraShaker._Update = nil
CameraShaker._OgCf = nil

function CameraShaker:Start(magnitude: number?, duration: number?): RBXScriptConnection
	magnitude = magnitude or 1.0
	self:Stop()
	RunService:BindToRenderStep("CamShake", Enum.RenderPriority.Camera.Value+1, function()
		self.Camera.CFrame = workspace.CurrentCamera.CFrame:ToWorldSpace(CFrame.new(self._Rng:NextUnitVector() * Vector3.new(1, 1, 0) * magnitude))
	end)
	if duration then
		task.delay(duration, function() self:Stop() end)
	end
end

function CameraShaker:Stop()
	RunService:UnbindFromRenderStep("CamShake")
end

return CameraShaker