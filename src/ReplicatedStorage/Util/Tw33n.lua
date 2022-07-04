local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local VecTools = require(ReplicatedStorage.Util.VecTools)

local Tw33n = {}

function Tw33n.tweenDescendantsOfClass(
	inst: Instance,
	class: string,
	twi: TweenInfo,
	properties: {string: any}
): {Tween}
	local tweens = {}
	for _, desc in pairs(inst:GetDescendants()) do
		if desc:IsA(class) then
			local tw = TweenService:Create(desc, twi, properties)
			tw:Play()
			tweens[#tweens+1] = tw
		end
	end
	return tweens
end

function Tw33n.ghostShift(model: Model, target: Vector3, duration: number, color: Color3?, imageRate: number?)
	color = color or BrickColor.new("Institutional white").Color
	imageRate = imageRate or 4

	local pos0 = model.PrimaryPart.Position
	local keypoints = VecTools.line(pos0, target, duration * imageRate)

	local cl
	for _, kp in pairs(keypoints) do
		cl = model:Clone()
		for _, desc in pairs(cl:GetDescendants()) do
			if desc:IsA("BasePart") then
				desc.Color = color
				local tw = TweenService:Create(desc, TweenInfo.new(), { Transparency = 1 })
				tw:Play()
				tw.Completed:Connect(function() desc:Destroy() end)
			end
		end
		cl:MoveTo(kp)
		cl.Parent = workspace
		task.wait(_G.time(duration / imageRate))
	end
end

function Tw33n.cubeSplit(pt: Part, twi: TweenInfo)
	for _, v in pairs({
		Vector3.new(1, 1, 1),
		Vector3.new(1, 1, -1),
		Vector3.new(1, -1, 1),
		Vector3.new(1, -1, -1),
		Vector3.new(-1, 1, 1),
		Vector3.new(-1, 1, -1),
		Vector3.new(-1, -1, 1),
		Vector3.new(-1, -1, -1),
	}) do
		local u = v * pt.Size/4
		local p = pt:Clone()
		p.CFrame = pt.CFrame:ToWorldSpace(CFrame.new(u))
		p.Size /= 2
		p.Parent = workspace
		local tw = TweenService:Create(p, twi, { CFrame = pt.CFrame:ToWorldSpace(CFrame.new(u*3)) })
		tw:Play()
		tw.Completed:Connect(function() p:Destroy() end)
	end
	pt:Destroy()
end

return Tw33n