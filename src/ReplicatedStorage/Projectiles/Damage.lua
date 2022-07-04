local Damage = {}

function Damage.projectile(cast: any, result: RaycastResult, dmgPacket: any, dealer: Player?)
	local self = {}
	self.Type = "Projectile"
	self.RaycastResult = {
		Instance = result.Instance,
		Position = result.Position,
	}
	self.Velocity = cast:GetVelocity()
	self.Acceleration = cast:GetAcceleration()
	self.Parriable = cast.Parriable
	self.Amount = dmgPacket
	self.Dealer = dealer
	return self
end

return Damage