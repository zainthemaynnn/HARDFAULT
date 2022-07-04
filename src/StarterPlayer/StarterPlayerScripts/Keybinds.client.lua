--!strict
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Beam = require(ReplicatedStorage.Effects.Beam)
local HitReg = require(ReplicatedStorage.HitReg)
local Sink = require(ReplicatedStorage.Sink)
local SFX = require(ReplicatedStorage.Effects.SFX)
local Keybind = require(ReplicatedStorage.Input.Keybind)
local PlayerModule = require(Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
local Projectiles = require(ReplicatedStorage.Projectiles)
local Tw33n = require(ReplicatedStorage.Util.Tw33n)

local CombatInfo = require(script.Parent.UI.CombatInfo.Store)
local Bestiary = require(script.Parent.UI.Bestiary.Store)
local Controls = PlayerModule:GetControls()

local Keybinds = {}
Keybinds.__index = Keybinds

local PARRY_CASTER = Projectiles.caster()
local PARRY_TIMING = 0.25
local PARRY_COOLDOWN = 1.0

PARRY_CASTER.RayHit:Connect(function() print("hit") end)

local Parry = {}

local parryHitbox = (function()
	local pt = Instance.new("Part")
	pt.BrickColor = BrickColor.new("Institutional white")
	pt.Size = Vector3.new(4, 5, 4)
	pt.Transparency = 1
	pt.Anchored = true
	pt.CanCollide = false
	pt.Material = Enum.Material.Neon
	pt.Shape = Enum.PartType.Ball
	pt.Name = "ParryHitbox"
	PhysicsService:SetPartCollisionGroup(pt, "Invulnerable")
	pt.Parent = workspace:WaitForChild("Junk")
	return pt
end)()

function Parry:TakeDamage(dmg: any)
	if dmg.Type == "Projectile" then
		if dmg.Cast.Parriable then
			local behavior = Projectiles.Caster.newBehavior()
			behavior.RaycastParams = RaycastParams.new()
			behavior.RaycastParams.CollisionGroup = "PlrProjectile"
			behavior.CosmeticBulletTemplate = dmg.Cast.RayInfo.CosmeticBulletObject:Clone()
			behavior.CosmeticBulletContainer = workspace.Junk
			PARRY_CASTER:Ricochet(
				dmg.Cast,
				dmg.Hit,
				nil,
				behavior,
				false
			)
			return HitReg.HitResult.Parry
		else
			return Keybinds:TakeDamage(dmg)
		end
	end
end

function unbindAll()
	for _, keybind in pairs(Keybinds) do
		keybind:Unbind()
	end
	Keybinds = {}
end

local blinkParams = RaycastParams.new()
blinkParams.CollisionGroup = "Invulnerable"

Sink:GetService("Player"):Sync(function(sink: any, plr: Player)
	if plr ~= Players.LocalPlayer then return end
	if not Players.LocalPlayer.Character then Players.LocalPlayer.CharacterAdded:Wait() end

	HitReg:MapSubject(Players.LocalPlayer.Character, Keybinds)
	HitReg:MapSubject(parryHitbox, Parry)

	local holstered = false

	local function getItem(slot: number?): any?
		local state = CombatInfo:getState()
		return state.Items[slot or state.Selected]
	end

	local function getMousePos(): Vector3
		local state = CombatInfo:getState()
		return state.MousePosition
	end

	function Keybinds:TakeDamage(dmg: any)
		sink:Get("TakeDamage"):FireServer(dmg.Amount)
	end

	sink:Get("Die"):Connect(function(deadPlr: Player, ragdoll: Model)
		local prompt = ragdoll.PrimaryPart:FindFirstChildWhichIsA("ProximityPrompt")
		prompt.Enabled = false
	end)

	sink:Get("Restock"):Connect(function(mags: number, slot: number)
		local item = getItem(slot)
		if item then item.Clip:Restock(mags) end
	end)

	local warpBeam = Beam.new(Instance.new("Beam", Players.LocalPlayer.Character.PrimaryPart))
	RunService.Heartbeat:Connect(function()
		parryHitbox.CFrame = Players.LocalPlayer.Character.PrimaryPart.CFrame
	end)

	setmetatable({
		["Use"] = Keybind.new("Use", function(inputState)
			local item = getItem()
			if not item or holstered then return false end
			item:Use(inputState, CombatInfo)
			CombatInfo:dispatch({
				type = "Used",
			})
			return true
		end, true)
			:Bind(Enum.UserInputType.MouseButton1),

		["Parry"] = Keybind.new("Parry", function(inputState)
			if inputState ~= Enum.UserInputState.Begin then return false end
			--Controls:Disable()
			PhysicsService:SetPartCollisionGroup(parryHitbox, "Player")
			parryHitbox.Transparency = 0
			local tw = TweenService:Create(
				parryHitbox,
				TweenInfo.new(_G.time(PARRY_TIMING)),
				{ Transparency = 1 }
			)
			tw:Play()
			tw.Completed:Connect(function()
				PhysicsService:SetPartCollisionGroup(parryHitbox, "Invulnerable")
				--Controls:Enable()
			end)
			return true
		end, true, _G.time(PARRY_COOLDOWN))
			:Bind(Enum.UserInputType.MouseButton2),

		["Blink"] = Keybind.new("Blink", function(inputState)
			if inputState ~= Enum.UserInputState.Begin then return false end
			local mousePos = getMousePos()

			local pos0 = Players.LocalPlayer.Character.PrimaryPart.Position
			local dir = (mousePos - pos0).Unit
			local fullDir = dir * plr.Character.Humanoid.WalkSpeed

			local res = workspace:Raycast(pos0, fullDir, blinkParams)
			local pos1 = if res then res.Position - dir else pos0 + fullDir

			Players.LocalPlayer.Character:SetPrimaryPartCFrame(
				CFrame.lookAt(pos1, mousePos)
			)

			warpBeam:SetTransparency(0)
			warpBeam:MoveTo(pos0, pos1)
			warpBeam:Fade(1, TweenInfo.new(0.5))

			sink:Get("Blink"):FireServer(pos0, dir)
			SFX:Play("Blink")
			return true
		end, true, 2.0)
			:Bind(Enum.KeyCode.LeftShift),

		--[[["Toggle slot"] = Keybind.new("Toggle slot", function(inputState)
			if inputState ~= Enum.UserInputState.Begin then return false end
			sink:Get("NewSlot"):FireServer()
			return true
		end, true)
			:Bind(Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonR1),--]]

		["Reload"] = Keybind.new("Reload", function(inputState)
			local item = getItem()
			if not item or inputState ~= Enum.UserInputState.Begin then return false end
			if item.Clip then
				item.Clip:Reload()
				sink:Get("Reload"):FireServer()
				task.delay(item.Clip.ReloadTime, function()
					CombatInfo:dispatch({
						type = "Reloaded",
					})
				end)
				-- 4713054746
				-- TODO: reload mouse icon
				return true
			else
				return false
			end
		end, true)
			:Bind(Enum.KeyCode.R),

		["Bestiary"] = Keybind.new("Bestiary", function(inputState)
			if inputState ~= Enum.UserInputState.Begin then return false end
			local state = Bestiary:getState()
			Bestiary:dispatch({
				type = "Activate",
				Active = not state.Active,
			})
			return true
		end, true)
			:Bind(Enum.KeyCode.Tab),
	}, Keybinds)
end)

return Keybinds