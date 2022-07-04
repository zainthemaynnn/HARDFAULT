local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SFX = require(ReplicatedStorage.Effects.SFX)

local Clip = {}
Clip.__index = Clip

type SoundPacket = {
	Fire: string,
	Empty: string,
	Reload: string,
	Restock: string,
}

local DEFAULT_SOUNDS = {
	Fire = "Pistol 1",
	Empty = "Clip empty",
	Reload = "Reload 1",
	Restock = "Restock",
}

local DEFAULT_MAG_N = 6

function Clip.new(magSize: number, reload: number, sounds: SoundPacket?, infinite: boolean?)
	local self = setmetatable({}, Clip)
	self.Infinite = if infinite == nil then false else infinite
	self.MagSize = magSize
	self.Capacity = if not self.Infinite then magSize * DEFAULT_MAG_N else 1e9 -- the lazy way
	self.Value = self.MagSize
	self.ReloadTime = reload
	self.Reloading = false
	self.Sounds = sounds or {}
	for k, v in pairs(DEFAULT_SOUNDS) do
		if not self.Sounds[k] then
			self.Sounds[k] = v
		end
	end
	return self
end

function Clip:Poll(): boolean
	if self.Reloading then
		return false
	elseif self.Value <= 0 then
		SFX:Play(self.Sounds.Empty)
		return false
	else
		self.Value -= 1
		SFX:Play(self.Sounds.Fire)
		return true
	end
end

function Clip:Reload()
	SFX:Play(self.Sounds.Reload)
	self.Reloading = true
	task.delay(_G.time(self.ReloadTime), function()
		self.Reloading = false
		local oldCapacity = self.Capacity
		self.Capacity = math.max(self.Capacity - (self.MagSize - self.Value), 0)
		self.Value = oldCapacity - self.Capacity
	end)
end

function Clip:Restock(mags: number)
	SFX:Play(self.Sounds.Restock)
	self.Capacity += self.MagSize * mags
end

return Clip