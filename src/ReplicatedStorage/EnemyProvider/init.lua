local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HitReg = require(ReplicatedStorage.HitReg)
local Sink = require(ReplicatedStorage.Sink)

local EnemyProvider = {}
EnemyProvider.__index = EnemyProvider

function EnemyProvider:TryFromInstance(inst: Instance): any?
	while inst do
		inst = inst:FindFirstAncestorWhichIsA("Model")
		if inst and self[inst.Name] then
			return self[inst.Name]
		end
	end
	return nil
end

function EnemyProvider:__newindex(_: string, enemy: any)
	HitReg:MapSubject(enemy.Model, enemy)
end

return setmetatable(Sink.provider(script:GetChildren(), true), EnemyProvider)