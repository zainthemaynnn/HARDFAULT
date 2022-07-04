local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local CharControl = require(ServerScriptService.Loadout.CharControl)
local HpModule = require(ServerScriptService.AI.HpModule)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Sink = require(ReplicatedStorage.Sink)

local BLINK_DISTANCE = 8.0
local RES_TIME = 3.0
local BASE_WALKSPEED = 16.0
local BASE_HP = 100
local BESTIARY_SIZE = #ServerScriptService.AI.Enemy:GetChildren()

local PlayerData = {}
PlayerData.PlayerAdded = Signal.new()

local Player = {}
Player.__index = Player
Player.SinkService = Sink:CreateService("Player", {
	"NewItem",
	"Use",
	"Holster",
	"Drop",
	"Reload",
	"Restock",
	"Blink",
	"Res",
	"TakeDamage",
	"NewSlot",
	"Die",
	"LoadBestiary",
	"EnemyDiscovered",
})

function Player.new(player)
	local self = setmetatable({}, Player)
	self.HpModule = HpModule.new(BASE_HP)
	self.Player = player
	self.Loadout = nil
	self.Items = {
		[1] = nil,
		[2] = nil,
	}
	self.Selected = 1
	self.Holstered = true
	self.Dead = false
	self.Ragdoll = nil

	self.Sink = self.SinkService:Relay(self.Player)

	self.Loadout = nil

	self.Bestiary = table.create(BESTIARY_SIZE) -- TODO
	self.Sink["LoadBestiary"]:FireClient(self.Player, self.Bestiary, BESTIARY_SIZE)

	self._RcParams = RaycastParams.new()

	self.Player.CharacterAdded:Connect(function(char)
		self._RcParams.FilterDescendantsInstances = {self.Player.Character}
		char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
		char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		char.Humanoid.JumpPower = 0

		char.Archivable = true
		self:SetHolstered(true)
		char:FindFirstChildWhichIsA("Humanoid").WalkSpeed = BASE_WALKSPEED
		for _, p in pairs(char:GetDescendants()) do
			if p:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(p, "Player")
			end
		end
		PhysicsService:SetPartCollisionGroup(char.PrimaryPart, "Player")
		PhysicsService:SetPartCollisionGroup(char.Head, "Player")

		self.Aura = (function()
			local aura = Instance.new("Part")
			aura.Transparency = 1
			aura.CanCollide = false
			aura.Size = Vector3.new(0, 5, 5)
			aura.Orientation = Vector3.new(0, 0, 90)
			aura.Shape = Enum.PartType.Cylinder

			local decal = Instance.new("Decal", aura)
			decal.Texture = "http://www.roblox.com/asset/?id=429500449"
			decal.Face = Enum.NormalId.Right
			decal.Transparency = .2
			return aura
		end)()

		self.Aura.Position = self:Downcast().Position
		self.Aura.Name = "Aura"
		self:_UpdateAuraColor()
		self.Aura.Parent = char
		local weld = Instance.new("WeldConstraint", self.Aura)
		weld.Part0 = self.Aura
		weld.Part1 = char.PrimaryPart

		task.wait(1.0)

		local Pistol = require(ServerScriptService.Loadout.Weapon.Pistol)
		local pistol = Pistol.new()
		self:SwapItem(pistol)
	end)

	self.HpModule.Damaged:Connect(function(...)
		self.Sink["TakeDamage"]:FireClient(self.Player, ...)
		self:_UpdateAuraColor()
	end)
	self.HpModule.Died:Connect(function() self:Die() end)

	self.Sink["Use"]:Connect(self:_RemoteScreen(function(...) self:Use(...) end))
	self.Sink["Holster"]:Connect(self:_RemoteScreen(function() self:SetHolstered(not self.Holstered) end))
	self.Sink["Drop"]:Connect(self:_RemoteScreen(function() self:SwapItem(nil) end))
	self.Sink["Blink"]:Connect(self:_RemoteScreen(function(...) self:VerifyBlink(...) end))
	self.Sink["NewSlot"]:Connect(self:_RemoteScreen(function() self:ToggleItem() end))
	self.Sink["Reload"]:Connect(self:_RemoteScreen(function() self:Reload() end))
	self.Sink["TakeDamage"]:Connect(self:_RemoteScreen(function(...) self:TakeDamage(...) end))

	self.SessionData = {
		Kills = 0,
		Hits = 0,
		Deaths = 0,
	}

	return self
end

function Player:_RemoteScreen(fn: (...any) -> ())
	return function(plr, ...)
		if plr == self.Player then
			fn(...)
		end
	end
end

function Player:SetLoadout(loadout: any)
	self.Loadout = loadout
	self.CharControl = CharControl.new(self.Player, loadout:Description())
	self.CharControl:LoadAppearance(true)
end

function Player:Use(...: any)
	local item = self:GetItem()
	if not item then return end
	item:Use(...)
end

function Player:GetItem(): any?
	return self.Items[self.Selected]
end

function Player:ToggleItem()
	self:HideItem()
	self.Selected = if self.Selected == 1 then 2 else 1
	local item = self:GetItem()
	if item then
		self:ShowItem()
		self:SetHolstered(false)
	else
		self:SetHolstered(true)
	end
	self.Sink["NewSlot"]:FireClient(self.Player, self.Selected)
end

function Player:SwapItem(item: any)
	local old = self:GetItem()
	if old then old.PickupPrompt:Unequip() end
	self.Items[self.Selected] = item

	if item then
		CharControl.addCustomAccessory(self.Player.Character, item.Model)
		self:SetHolstered(false)
	else
		self:SetHolstered(true)
	end

	self.Sink["NewItem"]:FireClient(self.Player, item and item.Sink:GetGUID(), self.Selected)
end

function Player:SetHolstered(on: boolean)
	self.Holstered = on

	if self.Holstered then
		local humDesc = self.CharControl.Description
		humDesc.IdleAnimation = 2510235063
		humDesc.WalkAnimation = 2510242378
		humDesc.RunAnimation = 2510238627
		self:HideItem()
	else
		local humDesc = self.CharControl.Description
		humDesc.IdleAnimation = 8388226219
		humDesc.WalkAnimation = 8388097306
		humDesc.RunAnimation = 9277125636
		self:ShowItem()
	end
	self.CharControl:LoadAppearance()
end

function Player:ShowItem()
	if not self:GetItem() then return end
	self:GetItem().Model.Parent = self.Player.Character
end

function Player:HideItem()
	if not self:GetItem() then return end
	self:GetItem().Model.Parent = nil
end

function Player:Reload()
	local item = self:GetItem()
	if not item then return end
	if not item.ReloadTime then return warn("Missing ReloadTime: " .. item.Name) end
	self.Player.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed *= 0.25
	task.wait(item.ReloadTime)
	self.Player.Character:FindFirstChildWhichIsA("Humanoid").WalkSpeed *= 4.0
end

function Player:Restock(mags: number)
	self.Sink["Restock"]:FireClient(self.Player, mags, self.Selected)
end

function Player:Die()
	self.Dead = true
	self.Player.Character.Parent = nil
	self.Ragdoll = self.Player.Character:Clone()
	self.Ragdoll.PrimaryPart.CanCollide = false
	self.Ragdoll.Parent = workspace

	local humanoid = self.Ragdoll:FindFirstChildWhichIsA("Humanoid")
	humanoid.PlatformStand = true
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

	-- TODO: this stupid thing still doesn't work, but it does the trick for now
	for _, joint in pairs(self.Ragdoll:GetDescendants()) do
		if joint:IsA("Motor6D") then
			joint.Enabled = false

			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.CFrame = joint.C0
			a1.CFrame = joint.C1
			a0.Parent = joint.Part0
			a1.Parent = joint.Part1

			local socket = Instance.new("BallSocketConstraint")
			socket.Attachment0 = a0
			socket.Attachment1 = a1
			socket.Parent = joint.Part0

		elseif joint:IsA("MeshPart") then
			local collisionClone = Instance.new("Part")
			collisionClone.Size = joint.Size
			collisionClone.CFrame = joint.CFrame
			collisionClone.Transparency = 1
			PhysicsService:SetPartCollisionGroup(collisionClone, "Invulnerable")
			collisionClone.Parent = joint

			local weld = Instance.new("WeldConstraint", joint)
			weld.Part0 = collisionClone
			weld.Part1 = joint

			joint:SetNetworkOwner(nil)
		end
		if joint:IsA("BasePart") then
			if joint.Name == "Aura" then
				joint:Destroy()
			else
				PhysicsService:SetPartCollisionGroup(joint, "Invulnerable")
			end
		end
	end

	self.SessionData.Deaths += 1

	self.Sink["Die"]:FireAllClients(self.Player, self.Ragdoll)
end

function Player:TakeDamage(dmg: any)
	self.HpModule:TakeDamage(dmg)
	self.SessionData.Hits += 1
end

function Player:AddKill()
	self.SessionData.Kills += 1
end

function Player:DiscoverEnemy(enemy)
	if self.Bestiary[enemy.BestiaryIndex] == nil then
		-- jank solution, but works
		if not enemy.VisualModel then
			getmetatable(enemy).VisualModel = enemy.BaseModel:Clone()
		end
		enemy.VisualModel.Parent = ReplicatedStorage
		self.Bestiary[enemy.BestiaryIndex] = true
		self.Sink["EnemyDiscovered"]:FireClient(self.Player, enemy.BestiaryIndex, {
			Name = enemy.Name,
			HP = enemy.BaseHp,
			Model = enemy.VisualModel,
			Resistances = enemy.Resistances,
			FlavorText = enemy.FlavorText,
		})
	end
end

function Player:VerifyBlink(pos0: Vector3, dir: Vector3)
	-- verified lmao
end

function Player:Downcast(): RaycastResult?
	if not self.Player.Character then return end
	return workspace:Raycast(self.Player.Character.PrimaryPart.Position, -Vector3.yAxis * 999, self._RcParams)
end

function Player:_UpdateAuraColor()
	self.Aura.Decal.Color3 = 
		BrickColor.new("Institutional white").Color
			:Lerp(BrickColor.new("Bright red").Color, (1 - self.HpModule:Percentage()))
end

Players.PlayerAdded:Connect(function(p)
	local pl = Player.new(p)
	PlayerData[p.UserId] = pl
	PlayerData.PlayerAdded:Fire(pl)
end)

Players.PlayerRemoving:Connect(function(p)
	PlayerData[p.UserId] = nil
end)

Players.CharacterAutoLoads = false

return PlayerData