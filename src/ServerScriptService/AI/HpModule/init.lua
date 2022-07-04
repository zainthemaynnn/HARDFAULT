-- is it programmatically correct to use HP or Hp? why not both?

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local CEnum = require(ReplicatedStorage.CEnum)
local Cooldown = require(ReplicatedStorage.Util.Cooldown)
local DamageMarshal = require(script.DamageMarshal)
--local PlayerData = require(ServerScriptService.Game.PlayerData)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Sink = require(ReplicatedStorage.Sink)

local HpModule = {}
HpModule.__index = HpModule
HpModule.SinkService = Sink:CreateService("Hp", {
	"DamageIndicator",
})

local WEIGHT_RESIST_NEGATION = {
	[CEnum.DamageWeight.Light]  =  0,
	[CEnum.DamageWeight.Medium] = .2,
	[CEnum.DamageWeight.Heavy]  = .5,
}

type DamagePacket = {
	Ballistic: string,
	Energy: string,
	Chemical: string,
	Fire: string,
}

function HpModule.new(maxHP: number, resist: {string: number}?, model: Model)
	resist = resist or {}

	local self = setmetatable({}, HpModule)
	self.MaxHP = maxHP
	self.HP = self.MaxHP
	self.Resist = {
		[CEnum.DamageAffinity.Ballistic] = resist[CEnum.DamageAffinity.Ballistic] or 0,
		[CEnum.DamageAffinity.Energy]    = resist[CEnum.DamageAffinity.Energy] or 0,
		[CEnum.DamageAffinity.Chemical]  = resist[CEnum.DamageAffinity.Chemical] or 0,
		[CEnum.DamageAffinity.Fire]      = resist[CEnum.DamageAffinity.Fire] or 0,
		Knockback = resist.Knockback or 0,
		Stagger = resist.Stagger or 0,
	}
	self.Model = model
	self.Damaged = Signal.new()
	self.Staggered = Signal.new()
	self.Died = Signal.new()
	self.Status = {
		Staggered = Cooldown.new(false),
		Dead = false,
	}
	self.Sink = self.SinkService:Relay()
	--[[self._DeathAttribution = self.Died:Connect(function(dmg: any)
		if dmg.Dealer then
			PlayerData[dmg.Dealer.UserId]:AddKill()
		end
	end)--]]
	return self
end

function HpModule:Percentage(): number
	return self.HP/self.MaxHP
end

function HpModule:_TakeSingleDamage(amount: number, affinity: string?, weight: string?): (number, number)
	local adjustedAmount
	if not affinity then
		adjustedAmount = amount
	else
		weight = weight or CEnum.DamageWeight.Light
		local resist = self.Resist[affinity]
		local negation = math.min(WEIGHT_RESIST_NEGATION[weight], resist)
		adjustedAmount = math.floor(amount * (1 - self.Resist[affinity] + negation))
	end
	self.HP -= adjustedAmount
	return adjustedAmount, if amount ~= 0 then adjustedAmount/amount else 1
end

function HpModule:_TakeRawDamage(damage: number | DamagePacket)
	local total = 0
	local adjustments = {}
	if typeof(damage) == "number" then
		local dmg, adjust = self:_TakeSingleDamage(damage)
		total += dmg
		adjustments[#adjustments+1] = adjust
	else
		local weight = damage.Weight
		for _, affinity in pairs(CEnum.DamageAffinity:Options()) do
			local amount = damage[affinity]
			if amount then
				local dmg, adjust = self:_TakeSingleDamage(amount, affinity, weight)
				total += dmg
				adjustments[#adjustments+1] = adjust
			end
		end
	end
	local adjust = 0
	for _, adj in pairs(adjustments) do adjust += adj end
	adjust /= #adjustments
	self.Damaged:Fire(total, adjust)
	if self.HP <= 0 and self.Status.Dead ~= true then
		self.Died:Fire(damage)
		self.Status.Dead = true
	end
	return total, adjust
end

function HpModule:TakeUserDamage(plr: Player, dmg: any)
	if DamageMarshal:VerifyDamage(dmg, plr, self) then
		self:TakeDamage(dmg)
	end
end

function HpModule:TakeDamage(dmg: any)
	if typeof(dmg) == "number" then
		self:_TakeRawDamage(dmg)
	else
		local kbResist = 1-self.Resist.Knockback
		local staggerResist = 1-self.Resist.Stagger

		local total, adjust = self:_TakeRawDamage(dmg.Amount)
		self.Sink["DamageIndicator"]:FireAllClients(total, adjust, dmg.RaycastResult.Position)
		local wasStaggered = self.Status.Staggered:Poll(dmg.Amount.Stagger * staggerResist)
		if not wasStaggered then
			self.Staggered:Fire()
		end

		if self.Model then
			if dmg.Type == "Projectile" then
				self.Model.PrimaryPart:ApplyImpulse(
					dmg.Velocity.Unit * self.Model.PrimaryPart.AssemblyMass * dmg.Amount.Knockback * kbResist
				)
			end
		end
	end
end

function HpModule:Heal(amount: number)
	self.HP = math.min(self.HP + amount, self.MaxHP)
end

function HpModule:Destroy()
	self.Damaged:DisconnectAll()
	self.Died:DisconnectAll()
end

return HpModule