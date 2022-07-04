local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local Overlay = Roact.Component:extend("VFXOverlay")

function Overlay:render()
    return Roact.createElement("ScreenGui", {
        IgnoreGuiInset = true,
    }, {
        Frame = Roact.createElement("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = self.props.Transparency,
            BackgroundColor3 = self.props.Color,
            BorderSizePixel = 0,
        }, {
            Text = Roact.createElement("TextLabel", {
                Text = self.props.Text,
                TextColor3 = BrickColor.new("Institutional white").Color,
                TextSize = 64,
                Font = Enum.Font.Code,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 1, 0),
            }),
        })
    })
end

return Roact.createElement(
    RoactRodux.connect(
        function(state, _)
            return {
                Transparency = state.Transparency,
                Color = state.Color,
                Text = state.Text,
            }
        end
    )(Overlay)
)