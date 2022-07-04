local Debris = game:GetService("Debris")

local Physics = {}

function Physics.impulse(part: Part, dir: Vector3, dist: number, t: number?)
	t = t or 0.1
	local m, a = part.AssemblyMass, dist/t^2
	local a0 = Instance.new("Attachment", part)
	local f = Instance.new("VectorForce")
	f.Attachment0 = a0
	f.Force = dir.Unit * m * a
	f.Parent = part
	Debris:AddItem(a0, t)
	Debris:AddItem(f, t)
end

return Physics