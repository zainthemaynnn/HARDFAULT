local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CEnum = require(ReplicatedStorage.CEnum)

local DAMAGE_INDICATORS = {
	[CEnum.Alliance.Tar] = (function()
		local e = Instance.new("ParticleEmitter")
		return e
	end)(),
	[CEnum.Alliance.Mech] = (function()
		local e = Instance.new("ParticleEmitter")
		return e
	end)()
}

local DamageIndicator = {}
DamageIndicator.__index = DamageIndicator

function DamageIndicator.new(hit: Part, pos: Vector3)
	local self = setmetatable({}, DamageIndicator)
	self._Holder = Instance.new("Attachment", hit)
	self._Holder.WorldPosition = pos
	self.Emitter = Instance.new("ParticleEmitter", self.Holder)
	return self
end

function DamageIndicator:Destroy()
	self._Holder:Destroy()
end

return DamageIndicator