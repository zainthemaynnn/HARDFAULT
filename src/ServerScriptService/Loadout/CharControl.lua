--!strict
local ServerScripts = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")

local CharControl = {}
CharControl.__index = CharControl

function CharControl.new(player: Player, humDesc: HumanoidDescription, accessories: {Accessory | Model})
	local self = setmetatable({}, CharControl)
	self.Player = player
	self.Description = humDesc or Instance.new("HumanoidDescription")
	self.Accessories = accessories or {}
	return self
end

function CharControl:LoadAppearance(reloadChar: boolean?)
	reloadChar = reloadChar or false

	local char: Model, humanoid: Humanoid
	if not reloadChar then
		char = self.Player.Character or self.Player.CharacterAdded:Wait()
		humanoid = char:WaitForChild("Humanoid")
		if not char:IsDescendantOf(workspace) then
			char.AncestryChanged:Wait()
		end
		humanoid:ApplyDescription(self.Description)
	else
		self.Player:LoadCharacterWithHumanoidDescription(self.Description)
	end

	for _, accessory in pairs(self.Accessories) do
		for _, p in pairs(accessory:GetDescendants()) do
			if p:IsA("BasePart") then
				PhysicsService:SetPartCollisionGroup(p, "Player")
			end
		end
		if accessory:IsA("Accessory") then
			humanoid:AddAccessory(accessory)
		elseif accessory:IsA("Model") then
			self.addCustomAccessory(char, accessory)
		end
	end
end

function CharControl.addCustomAccessory(model: Model, accessory: Model, collisionGroup: string)
	local handle = accessory:FindFirstChild("Handle")
	if not handle then return warn(("Custom accessory %s missing Handle; skipping"):format(model.Name)) end

	local handleAttachment = handle:FindFirstChildOfClass("Attachment") :: Attachment
	if not handleAttachment then return warn(("Custom accessory %s missing Handle attachment; skipping"):format(model.Name)) end

	local characterAttachment do
		for _, v in ipairs(model:GetDescendants()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
				PhysicsService:SetPartCollisionGroup(v, collisionGroup or "Invulnerable")
			elseif v:IsA("Attachment") and v.Name == handleAttachment.Name then
				characterAttachment = v :: Attachment
				break
			end
		end
	end

	if not characterAttachment then return warn(("Custom accessory %s contains unmatching attachment %s; skipping"):format(model.Name, handleAttachment.Name)) end

	local attachmentWeld = Instance.new("Motor6D")
	attachmentWeld.Part0 = characterAttachment.Parent :: BasePart
	attachmentWeld.Part1 = handleAttachment.Parent :: BasePart
	attachmentWeld.C0 = characterAttachment.CFrame
	attachmentWeld.C1 = handleAttachment.CFrame
	attachmentWeld.Name = "CharWeld"
	attachmentWeld.Parent = accessory
	accessory.Parent = model

	CharControl.physicsLoad(model)
end

function CharControl.unweldCustomAccessory(accessory: Model)
	local weld = accessory:FindFirstChild("CharWeld")
	if weld then weld:Destroy() end
end

-- the welds don't actually act until parented to workspace
-- which messes with Model:GetExtentsSize()
-- this fix hopefully won't be an issue unless I end up
-- doing funky stuff with AncestryChanged
-- in that case I'll just use GetExtentsSize
-- before putting the accessories on
-- hopefully this doesn't impact performance that much
function CharControl.physicsLoad(model: Model)
	local cf0, cf1 = model.PrimaryPart.CFrame, CFrame.new(Vector3.new(1e3,1e3,1e3))
	local p0, p1 = model.Parent, workspace
	model:SetPrimaryPartCFrame(cf1)
	model.Parent = p1
	local conn do
		conn = RunService.Stepped:Connect(function()
			conn:Disconnect()
			model.Parent = p0
			model:SetPrimaryPartCFrame(cf0)
		end)
	end
end

return CharControl