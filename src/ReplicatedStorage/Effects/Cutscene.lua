local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Dialog = require(Players.LocalPlayer.PlayerScripts.UI.Dialog.Store)
local DM = require(ReplicatedStorage.DialogueManager)
local VFX = require(Players.LocalPlayer.PlayerScripts.UI.VFX.Store)
local Explosion = require(ReplicatedStorage.Effects.Explosion)
local SFX = require(ReplicatedStorage.Effects.SFX)
local Signal = require(ReplicatedStorage.Packages.Signal)

-- every cutscene has an animation part aand scripted events part
-- indeed, animating has to be the most annoying thing on this engine
-- I pity @xSIXx
local Cutscene = {}
Cutscene.__index = Cutscene

function Cutscene.new(anims: {AnimData}, concurrentThread: {[string]: ({Instance}) -> ()}?)
	local self = setmetatable({}, Cutscene)
	self.Tracks = {}
	self.Props = {}
	self.Thread = concurrentThread
	for _, v in pairs(anims) do
		if v.Rig:IsA("Camera") then
			local values = v.Animation.Frames:GetChildren()
			self.CamTrack = table.create(#values)
			self.Camera = v.Rig
			for _, vv in pairs(values) do
				if vv:IsA("CFrameValue") then
					self.CamTrack[tonumber(vv.Name)] = vv.Value
				end
			end
		else
			local rig = v.Rig:Clone()
			self.Props[rig.Name] = rig
			rig.Parent = workspace
			local animator = rig:FindFirstChildWhichIsA("Animator") or Instance.new("Animator", rig:FindFirstChildWhichIsA("Humanoid"))
			self.Tracks[#self.Tracks+1] = animator:LoadAnimation(v.Animation)
		end
	end
	return self
end

function Cutscene:Play()
	for _, track in pairs(self.Tracks) do
		track:Play()
	end
	if self.CamTrack then
		self:PlayCamTrack()
	end
	if self.Thread then
		self._TimerTrack.KeyframeReached:Connect(function(kf)
			if self.Thread[kf] then self.Thread[kf](self.Props) end
		end)
	end
end

function Cutscene:PlayCamTrack()
	local conn do
		local i = 1
		conn = RunService.RenderStepped:Connect(function()
			if i >= #self.CamTrack then return conn:Disconnect() end
			self.Camera.CFrame = self.CamTrack[i]
			i += 1
		end)
	end
end

function Cutscene.fromAnimId(id: number)
	local a = Instance.new("Animation")
	a.AnimationId = "rbxassetid://" .. tostring(id)
	a.Parent = ReplicatedStorage
	return a
end

Cutscene.STORED = {
	["1:1 Intro"] = Cutscene.new({
		{
			Rig = workspace.Black,
			Animation = Cutscene.fromAnimId(9896782142),
		},
		{
			Rig = workspace.White,
			Animation = Cutscene.fromAnimId(9896792118),
		},
		{
			Rig = workspace.CurrentCamera,
			Animation = workspace.Cutscene.Intro_Camera,
		},
	},
	function()
		local black = workspace.Black:Clone()
		local white = workspace.White:Clone()
		local explosion = Explosion.new(nil, nil, BrickColor.new("Electric blue").Color)
		SFX:Play("Ambient lab")
		task.wait(1.0)
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "Dr. Wong?",
			Profile = black,
			Timing = 1.5,
		})
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "Kevin! Uh, I'm not in trouble again am I?",
			Profile = white,
			Timing = 3.0,
		})
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "Nope. Just distributing paychecks today.",
			Profile = black,
			Timing = 3.0,
		})
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "Wow. They got you on mail service?",
			Profile = white,
			Timing = 3.0,
		})
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "You haven't caused an accident in about two weeks, so yes, I'm on mail service.",
			Profile = black,
			Timing = 5.5,
		})
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "What's with the painting?",
			Profile = black,
			Timing = 3.0,
		})
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "Glad you asked. It's scientifically proven to be one of the most unsettling images on Earth.",
			Profile = white,
			Timing = 5.5,
		})
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "What the hell?",
			Profile = black,
			Timing = 5.5,
		})
		Dialog:dispatch({
			type = "QueueDialog",
			Text = "Stay put.",
			Profile = black,
			Timing = 2.0,
		})
		Dialog:dispatch({
			type = "NextDialog",
		})
		task.wait(24.5)
		SFX:Play("Zap")
		SFX:Play("Ambient gunfire")
		Lighting.Ambient = Color3.new()
		task.wait(33.0-25.5-6/60)
		SFX:Play("Boom")
		explosion:Spawn(workspace.Lab.Table.ExplodoSphere.Position, 20.0, 6/60)
		explosion.Finished:Connect(function()
			SFX:Play("Flesh 1")
			SFX:Stop("Ambient gunfire")
			SFX:Stop("Ambient lab")
			VFX:dispatch({
				type = "SetOverlay",
				Transparency = 0,
				Text = "Lab Rats"
			})
			task.wait(5.0)
			VFX:dispatch({
				type = "SetOverlay",
				Transparency = 1,
				Text = "",
			})
		end)
	end),

	["BossDoor"] = Cutscene.new({
		{
			Rig = workspace.Black,
			Animation = Cutscene.fromAnimId(9896782142),
		},
		{
			Rig = workspace.White,
			Animation = Cutscene.fromAnimId(9896792118),
		},
		{
			Rig = workspace.Agent,
			Animation = Cutscene.fromAnimId(9896782142),
		},
		{
			Rig = workspace.Guard,
			Animation = Cutscene.fromAnimId(9896792118),
		},
		{
			Rig = workspace.CurrentCamera,
			Animation = workspace.Cutscene.Intro_Camera,
		},
	},
	{
		["1"] = function(props) DM:Say(props.Black, "Dupuis? Sir? You're still here?") end,
		["2"] = function(props) DM:Say(props.Guard, "Hm. Glad to see you. Roma and I spent most of the time evacuating people through KRONOS. Most people have either died or left.") end,
		["3"] = function(props) DM:Say(props.Agent, "and my voice synthesizer broke. throat dead. need 2 use my phone now. sup.") end,
		["4"] = function(props) DM:Say(props.White, "I've got a better question: who are you and what is happening?") end,
		["5"] = function(props) DM:Say(props.Guard, "I'm his boss, the head of security. Allow me to ask: were either of you aware that we used to have an AI in control of the facility's systems?") end,
		["6"] = function(props) DM:Say(props.White, "SmileByte? I remember. Early last year, but they took it off the next day.") end,
		["7"] = function(props) DM:Say(props.Black, "Bruh... you're telling me they called it \"SmileByte?\" Are they five years old?") end,
		["8"] = function(props) DM:Say(props.Guard, "They \"took it off\" because it was unstable. Psychologically. I don't know why, but it's back on the network. All of our machines are compromised.") end,
		["9"] = function(props) DM:Say(props.White, "What about those black and red things?") end,
		["10"] = function(props) DM:Say(props.Guard, "Not sure, but seems to be unrelated. They're not machines.") end,
		["11"] = function(props) DM:Say(props.Black, "My personal hypothesis is aliens.") end,
		["12"] = function(props) DM:Say(props.Agent, "nah, zombies.") end,
		["13"] = function(props) DM:Say(props.White, "So our entire facility is screwed. Do we even have a chance?") end,
		["14"] = function(props) DM:Say(props.Guard, "Realistically speaking: we are in one of the deepest areas of the facility. I doubt we will all make it to the exit, if at all. Our goal is simply to rescue as many civilians as possible, along with ourselves. Stopping the AI is secondary, and probably impossible.") end,
		["15"] = function(props) DM:Say(props.Guard, "The optimal route should be through KRONOS, the sim room, and then harmonics. With only four of us, we will have to play it carefully.") end,
		["16"] = function(props) DM:Say(props.Agent, "u guys might want to look over there.") end,
		["17"] = function(props) DM:Say(props.Black, "Boss time? EEEZZZ CLAPS") SFX:Play("Screech") end,
	}),
}

return Cutscene