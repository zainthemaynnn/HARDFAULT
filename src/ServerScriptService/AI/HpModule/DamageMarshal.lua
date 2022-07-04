-- this should be used for exploit protection
-- as you can see, I've written absolutely nothing
-- yes this is social commentary
local DamageMarshal = {}

function DamageMarshal:VerifyDamage(damage: number | any, dealer: Player, receiver): boolean
	return true
end

return DamageMarshal