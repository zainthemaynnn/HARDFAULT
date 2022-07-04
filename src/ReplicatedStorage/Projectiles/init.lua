local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PartCache = require(ReplicatedStorage.Packages.PartCache)
local Caster = require(script.Caster)

local Projectiles = {}

local PARRY_CASTER = Caster.new()

Projectiles.VecTools = require(ReplicatedStorage.Util.VecTools)
Projectiles.Damage = require(script.Damage)
Projectiles.Caster = Caster
Projectiles.PartCache = PartCache

Projectiles.Orb = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(1, 1, 1)
	pt.Shape = Enum.PartType.Ball
	PhysicsService:SetPartCollisionGroup(pt, "NPCProjectile")
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	return pt
end)()

Projectiles.Shot = (function()
	local pt = Instance.new("Part")
	pt.Size = Vector3.new(0.5, 0.5, 1.0)
	PhysicsService:SetPartCollisionGroup(pt, "NPCProjectile")
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	return pt
end)()

Projectiles.BlueOrb = (function()
	local pt = Projectiles.Orb:Clone()
	pt.BrickColor = BrickColor.new("Electric blue")
	return pt
end)()

Projectiles.BlueShot = (function()
	local pt = Projectiles.Shot:Clone()
	pt.BrickColor = BrickColor.new("Electric blue")
	return pt
end)()

Projectiles.RedOrb = (function()
	local pt = Projectiles.Orb:Clone()
	pt.BrickColor = BrickColor.new("Crimson")
	return pt
end)()

Projectiles.RedShot = (function()
	local pt = Projectiles.Shot:Clone()
	pt.BrickColor = BrickColor.new("Crimson")
	return pt
end)()

function Projectiles.caster(partcache: any?, collisionGroup: string?): any
	return Caster.new(partcache, collisionGroup)
end

function Projectiles.castBehavior()
	return Caster.newBehavior()
end

function Projectiles.partcache(templ: BasePart, precreated: number?)
	return PartCache.new(templ, precreated, Instance.new("Folder", workspace.Junk))
end

Projectiles.updatePosition = Caster.updatePosition

function Projectiles.localHit(instance: Instance): boolean
	local char = instance:FindFirstAncestor(Players.LocalPlayer.Character.Name)
	return char and char == Players.LocalPlayer.Character
end

return Projectiles