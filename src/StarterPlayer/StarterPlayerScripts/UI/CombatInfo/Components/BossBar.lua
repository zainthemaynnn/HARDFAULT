-- TODO: ghost hp?
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local BossBar = Roact.Component:extend("BossBar")

function BossBar:init()
    self.BarMotor = Flipper.SingleMotor.new(1)
    local binding, setbinding = Roact.createBinding(self.BarMotor:getValue())
    self.Binding = binding
    self.BarMotor:onStep(setbinding)
end

function BossBar:willUpdate(newProps)
    if newProps.HP then
        self.BarMotor:setGoal(Flipper.Spring.new(newProps.HP, {
            frequency = 2,
            dampingRatio = 1,
        }))
    end
end

function BossBar:render()
    if self.props.Name then
        return Roact.createElement("ScreenGui", nil, {
            Frame = Roact.createElement("Frame", {
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(.5, 0, 0, 20),
                BackgroundColor3 = BrickColor.new("Really black").Color,
                BorderSizePixel = 0,
                ZIndex = 0,
            }, {
                Bar = Roact.createElement("Frame", {
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = self.Binding:map(function(hp)
                        return UDim2.new(hp, 0, 1, 0)
                    end),
                    BackgroundColor3 = BrickColor.new("Crimson").Color,
                    BorderSizePixel = 0,
                    ZIndex = 2,
                })
            }),

            Name = Roact.createElement("TextLabel", {
                Text = string.upper(self.props.Name),
                TextSize = 24,
                TextColor3 = BrickColor.new("Institutional white").Color,
                Font = Enum.Font.Code,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Position = UDim2.new(0, 0, 0, 20),
                Size = UDim2.new(0, 120, 0, 20),
                TextXAlignment = Enum.TextXAlignment.Left,
            }),
        })
    else
        return Roact.createElement("ScreenGui")
    end
end

return Roact.createElement(
    RoactRodux.connect(
        function(state, _)
            return {
                Name = state.Boss and state.Boss.Name,
                HP = state.Boss and state.Boss.Hp,
            }
        end
    )(BossBar)
)