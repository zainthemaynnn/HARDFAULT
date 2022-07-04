-- TODO: ghost hp?
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local SFX = require(ReplicatedStorage.Effects.SFX)

local HPBar = Roact.Component:extend("HPBar")

local INITIAL_HP = 100

function HPBar:init()
    self.BarMotor = Flipper.SingleMotor.new(INITIAL_HP)
    local binding, setbinding = Roact.createBinding(self.BarMotor:getValue())
    self.Binding = binding
    self.BarMotor:onStep(setbinding)
end

function HPBar:willUpdate(newProps)
    self.BarMotor:setGoal(Flipper.Spring.new(newProps.HP, {
        frequency = 2,
        dampingRatio = 1,
    }))
end

function HPBar:render()
    return Roact.createElement("ScreenGui", nil, {
        Frame = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(.25, 0, 0, 8),
            BackgroundColor3 = BrickColor.new("Really black").Color,
            BorderSizePixel = 0,
            ZIndex = 0,
        }, {
            Bar = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = self.Binding:map(function(hp)
                    return UDim2.new(hp/self.props.MaxHP, 0, 1, 0)
                end),
                BackgroundColor3 = self.Binding:map(function(hp)
                    return BrickColor.new("Institutional white").Color:Lerp(BrickColor.new("Bright red").Color, (1 - hp/self.props.MaxHP))
                end),
                BorderSizePixel = 0,
                ZIndex = 2,
            })
        })
    })
end

return Roact.createElement(
    RoactRodux.connect(
        function(state, _)
            return {
                HP = state.HP,
                MaxHP = state.MaxHP,
            }
        end
    )(HPBar)
)