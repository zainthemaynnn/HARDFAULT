local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CEnum = require(ReplicatedStorage.CEnum)

local HitReg = {}
HitReg.__index = HitReg

HitReg.HitResult = CEnum.HitResult

type HitSubject = {
	TakeDamage: (any) -> (),
	[any]: any,
}

function HitReg:MapSubject(inst: Instance, subject: HitSubject)
	HitReg[inst] = subject
end

function HitReg:TryGet(inst: Instance): HitSubject?
	if self[inst] then
		return self[inst]
	end
	while inst.Parent do
		inst = inst.Parent
		if self[inst] then
			return self[inst]
		end
	end
	return nil
end

return setmetatable({}, HitReg)