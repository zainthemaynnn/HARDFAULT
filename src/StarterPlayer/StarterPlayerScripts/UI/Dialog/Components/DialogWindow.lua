local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local SFX = require(ReplicatedStorage.Effects.SFX)

local DialogWindow = Roact.Component:extend("DialogWindow")

local PUNCTUATION = {
    ["."] = true,
    [","] = true,
    [":"] = true,
    [";"] = true,
    ["!"] = true,
    ["?"] = true,
}
local WRITE_SPEED_SEC = 30
local PUNCTUATION_STOP = 0.2
local POST_FINISH_COUNTDOWN = 2.0
local PROFILE_OFFSET_STUDS = 2.0

function DialogWindow:init()
    self.Viewport = Roact.createRef()
    self.Camera = Roact.createRef()
    self.CamCF = nil

    self.TextMotor = Flipper.SingleMotor.new(0)
    local tbinding, tsetBinding = Roact.createBinding(self.TextMotor:getValue())
    self.TextBuf = ""
    self.CharIt = (""):gmatch(".")
    self.TextBinding = tbinding
    self.TextMotor:onStep(tsetBinding)

    self.PositionMotor = Flipper.SingleMotor.new(0)
    local pbinding, psetBinding = Roact.createBinding(self.PositionMotor:getValue())
    self.PositionBinding = pbinding
    self.PositionMotor:onStep(psetBinding)
end

function DialogWindow:willUpdate(newProps)
    if newProps.Active then
        if self.props.Profile then self.props.Profile:Destroy() end
        self.TextBuf = ""
        self.CharIt = newProps.Text:gmatch(".")
        self.TextMotor:setGoal(Flipper.Instant.new(0))
        self.TextMotor:step()
        self.TextMotor:setGoal(Flipper.Linear.new(#newProps.Text, { velocity = WRITE_SPEED_SEC }))

        self.PositionMotor:setGoal(Flipper.Spring.new(1, {
            frequency = 1,
            dampingRatio = 1
        }))

        newProps.Profile.Parent = self.Viewport:getValue()
    else
        task.delay(_G.time(POST_FINISH_COUNTDOWN), function()
            self.PositionMotor:setGoal(Flipper.Spring.new(0, {
                frequency = 1,
                dampingRatio = 1
            }))
        end)
    end
end

function DialogWindow:render()
    local focus = self.props.Profile and self.props.Profile.Head.CFrame
    if focus then
        self.CamCF = CFrame.lookAt(focus.Position + focus.LookVector*PROFILE_OFFSET_STUDS, focus.Position)
    end
    return Roact.createElement("ScreenGui", nil, {
        Frame = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(0, 1),
            Position = self.PositionBinding:map(function(a)
                return UDim2.new(0, 0, 1, 180):Lerp(UDim2.new(0, 0, 1, 0), a)
            end),
            Size = UDim2.new(1, 0, 0, 180),
            BackgroundColor3 = BrickColor.new("Really black").Color,
            BorderSizePixel = 0,
        }, {
            Profile = Roact.createElement("ViewportFrame", {
                Position = UDim2.new(0, 20, 0, 20),
                Size = UDim2.new(0, 140, 0, 140),
                BackgroundTransparency = 1,
                CurrentCamera = self.Camera,
                [Roact.Ref] = self.Viewport,
            }, {
                Camera = Roact.createElement("Camera", {
                    CFrame = self.CamCF,
                    [Roact.Ref] = self.Camera,
                })
            }),
            Text = Roact.createElement("TextLabel", {
                Position = UDim2.new(0, 180, 0, 20),
                Size = UDim2.new(.5, -200, 0, 140),
                BackgroundTransparency = 1,
                TextColor3 = BrickColor.new("Institutional white").Color,
                TextSize = 18,
                TextWrapped = true,
                TextXAlignment = Enum.TextXAlignment.Left,
                Text = self.TextBinding:map(function(v)
                    local i = math.floor(v)

                    if i >= #self.TextBuf+1 then
                        -- note: this may cause an issue with low frame rate where
                        -- some letters following the punctuation will be rendered before pausing
                        -- but they are usually followed by a space so only 3+ characters at once is a problem
                        -- and most importantly I am too lazy to fix it
                        local chars = {}
                        for _=1,i-#self.TextBuf do
                            local char = self.CharIt()
                            table.insert(chars, char)
                            if PUNCTUATION[char] then
                                self.TextMotor:stop()
                                task.delay(_G.time(PUNCTUATION_STOP), function() self.TextMotor:start() end)
                            end
                        end
                        self.TextBuf = table.concat({self.TextBuf, table.unpack(chars)})
                        SFX:Play("Text")
                    end

                    if i >= #self.props.Text and i ~= 0 then
                        task.delay(_G.time(POST_FINISH_COUNTDOWN), self.props.GetNextDialog)
                    end

                    return self.TextBuf
                end),
                Font = Enum.Font.Gotham,
            }),
            Gradient = Roact.createElement("UIGradient", {
                Transparency = NumberSequence.new(0, 1),
                Rotation = 270.0,
            }),
        })
    })
end

return Roact.createElement(
    RoactRodux.connect(
        function(state, _)
            return {
                Text = state.Text or "",
                Profile = state.Profile and state.Profile:Clone(),
                Active = state.Active,
            }
        end,
        function(dispatch)
            return {
                GetNextDialog = function()
                    dispatch({
                        type = "NextDialog",
                    })
                end,
            }
        end
    )(DialogWindow)
)