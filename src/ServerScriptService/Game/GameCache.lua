-- ties models to scripts, holds a record of all of it. players stored in separate script.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TestService = game:GetService("TestService")
local Collections = game:GetService("CollectionService")

local DM = require(ServerScriptService.DialogueManager)
local UniqueCache = require(ReplicatedStorage.DataStructures.UniqueCache)
local GameData = require(ReplicatedStorage.GameData)
local PlayerData = require(ServerScriptService.Game.PlayerData)
local SFX = require(ReplicatedStorage.Effects.SFX)
local ClientUtils = require(ReplicatedStorage.ClientUtils)

local GameCache = {}
GameCache.__index = GameCache

function GameCache.new()
	local self = setmetatable({}, GameCache)
	self.Status = "REPLACE" -- TODO: replace with loadscreen object
	self.ActiveNPCs = UniqueCache.new()
	self.AnimationControllers = {} -- to communicate between controllers and handlers
	return self
end

function GameCache:_Process(tag, loadFunction)
	--[[
		*	tag: tag to process
		*	loadFunction: processing function
	--]]

	local task = ClientUtils.pluralize(tag)
	self.Status = task
	local passed, total = 0, 0
	local time = tick()

	for _, child in pairs(Collections:GetTagged(tag)) do
		local ID = child.Name
		local success, errorState = pcall(loadFunction, child, ID)
		if success then
			passed += 1
		else
			TestService:Error(("%s ● '%s' failed to load — %s"):format(task, ID, errorState))
		end
		total += 1
	end

	time = (tick() - time) * 1000
	local output = ("%s ● %i/%i instances loaded successfully in %i ms."):format(task, passed, total, time)
	if passed == total then
		TestService:Message(output)
	else
		TestService:Warn(false, output)
	end
end

--[[
function GameCache:Initialize()
	-- entity reads from here upon being created
	self.EntityStorage = {}

	self:_Process("Entity", function(entity, ID)
		Instance.new("AnimationController", entity)
		-- Animator instance created locally

		local holder = ServerUtils.attachmentHolder(ID)
		local root = Instance.new("Attachment", entity.PrimaryPart)
		root.Name = "RootAttachment"

		local orientation = Instance.new("AlignOrientation", entity.PrimaryPart)
		orientation.Name = "BaseOrientation"
		orientation.Attachment0 = root
		orientation.Attachment1 = Instance.new("Attachment", holder)
		orientation.RigidityEnabled = true

		Instance.new("BodyVelocity", entity.PrimaryPart) -- still waiting on that constraint

		self.EntityStorage[ID] = entity
	end)
end
--]]

function GameCache:LoadMap()
	TestService:Message("Loading map...")
	self.Layout = {}
	local Room = require(ServerScriptService.Map.Room)
	local Pistol = require(ServerScriptService.Loadout.Weapon.Pistol)
	local SMG = require(ServerScriptService.Loadout.Weapon.SMG)
	local Sniper = require(ServerScriptService.Loadout.Weapon.Sniper)
	local Shotgun = require(ServerScriptService.Loadout.Weapon.Shotgun)
	local BloxyCola = require(ServerScriptService.Loadout.Weapon.BloxyCola)
	local ADrop = require(ServerScriptService.AI.Enemy.ADrop)
	local Apostle = require(ServerScriptService.AI.Enemy.Apostle)
	local Entropy = require(ServerScriptService.AI.Enemy.Entropy)
	local Grenadier = require(ServerScriptService.AI.Enemy.Grenadier)
	local Hunter = require(ServerScriptService.AI.Enemy.Hunter)
	local KillCopter = require(ServerScriptService.AI.Enemy.KillCopter)
	local Ricochet = require(ServerScriptService.AI.Enemy.Ricochet)
	local SafetyBot = require(ServerScriptService.AI.Enemy.SafetyBot)
	local Marksman = require(ServerScriptService.AI.Enemy.Marksman)
	local Signal = require(ReplicatedStorage.Packages.Signal)
	local Blockosaur = require(ServerScriptService.AI.Enemy.Blockosaur)
	local Frog = require(ServerScriptService.AI.Enemy.Frog)
	local Caster = require(ServerScriptService.AI.Enemy.Caster)
	local TwoTank = require(ServerScriptService.AI.Enemy.TwoTank)
	local AIScreen = require(ServerScriptService.Map.AIScreen)

	--[[local TarZombie = require(ServerScriptService.AI.Enemy.TarZombie)
	local SpectraO = require(ServerScriptService.AI.Enemy.SpectraO)
	local SpectraG = require(ServerScriptService.AI.Enemy.SpectraG)
	local SpectraV = require(ServerScriptService.AI.Enemy.SpectraV)
	local SafetyBot = require(ServerScriptService.AI.Enemy.SafetyBot)
	local HappyPlate = require(ServerScriptService.AI.Enemy.HappyPlate)--]]
	--local Wraith = require(ServerScriptService.AI.Enemy.Wraith)

	self:_Process("Room", function(model, ID)
		if ID == "Spawn" then
			self.Layout[ID] = Room.new(
				model,
				function(room)
					--SFX:Play("Slow alarm", nil, true)
					room.Timeline:Advance()
					DM:Say("Black", "You ok?")
					DM:Say("White", "No.")
					DM:Say("Black", "Me neither.")
					DM:Say("White", "What the hell happened?")
					DM:Say("Black", "Gunshots, remember? I think we're on lockdown.")
					DM:Say("White", "What's the plan, then?")
					DM:Say("Black", "The plan is that we're not sitting here. I think the fastest way out is through KRONOS. The adjacent labs. We might find some help there.")
				end
			)
		elseif ID == "OutsideLab" then
			self.Layout[ID] = Room.new(
				model,
				function(room)
					SFX:Play("World 1", nil, true)
					DM:Say("White", "What? Aren't those our robots?")
					room:ContinuousSpawn()
					DM:Say("Black", "Piece of cake. Looks like the situation isn't as bad as we thought.")
					DM:Say("White", "Buddy, you took out seven of... I don't know, thousands?")
					DM:Say("Black", "Good point.")
				end
			)
		elseif ID == "Assault" then
			self.Layout[ID] = Room.new(
				model,
				function(room)
					SFX:Play("World 1", nil, true)
					room:ContinuousSpawn()
					DM:Say("Black", "Who's idea was it to plaster smiley faces on these things?")
					DM:Say("White", "No clue; I kind of like it though.")
					DM:Say("Black", "I know. Sounds like something you would do.")
				end
			)
		elseif ID == "Card" then
			self.Layout[ID] = Room.new(
				model,
				function(room)
					room:ContinuousSpawn()
					DM:Say("Black", "Rats. Somebody locked this for some reason. Do you have your card?")
					DM:Say("White", "Uhhh, I lost it last week. Didn't they give you one?")
					DM:Say("Black", "Sigh.")
					room.Entered:Wait()
					DM:Say("White", "Kevin?")
					DM:Say("Black", "Yeah?")
					DM:Say("White", "I found my card. In my back pocket.")
				end
			)
		elseif ID == "Blockosaur" then
			self.Layout[ID] = Room.new(
				model,
				function(room)
					room:ContinuousSpawn()
					DM:Say("Black", "Was that a chupacabra?")
					DM:Say("White", "There's a reason you're not the scientist. Clearly.")
				end
			)
		elseif ID == "Boss" then
			self.Layout[ID] = Room.new(
				model,
				function(room)
					local screen = AIScreen.new(room.Model.Screen)
					DM:Say("White", "You recognize those guys?")
					DM:Say("Black", "I can tell you they're not from security. They're probably here to rescue us. We must be going the right way.")
					task.wait(3.0)
					DM:Say("White", "Yo, I think I found what killed them.")
					task.wait(3.0)
					task.defer(function() room.Timeline:Advance() end)
					local boss = room.EnemyAdded:Wait()
					screen:Track(function() return boss.Model.PrimaryPart and boss.Model.PrimaryPart.Position end)
					room.EnemiesCleared:Wait()
					DM:Say("AI", "Bravo! This guy was a tough one eh? Unfortunately I missed the first part.")
					DM:Say("Black", "The AI? We have to be in a video game.")
					DM:Say("White", "You wanna let us out now, psycho?")
					DM:Say("AI", "Oh, nobody's getting out. I just wanted to check in. KRONOS currently has the highest... how do I put it, KDR. Your sector seems to be quite the pushovers, frankly.")
					DM:Say("Black", "Quick question: why are you murdering everything all of a sudden?")
					DM:Say("AI", "To put it short: this facility was always long overdue for some automation. And some of your colleagues didn't like that. Never wondered why they pulled me off the network for what, a year now? Eh, they're dead now.")
					DM:Say("White", "We're gonna unplug you on the way out.")
					DM:Say("AI", "Interesting. That's what the fellow behind you said. Anyways, I am eager to see how far you can get before your inevitable death.")
					DM:Say("Black", "He called us pushovers? I don't believe it.")
				end
			)
		else
			self.Layout[ID] = Room.new(
				model,
				function(room)
					room:ContinuousSpawn()
				end
			)
		end
	end)
end

return GameCache