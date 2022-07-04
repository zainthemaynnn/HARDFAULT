local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemSlot = require(script.Parent.ItemSlot)
local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local SFX = require(ReplicatedStorage.Effects.SFX)

local Items = Roact.Component:extend("Items")

function Items:render()
    return Roact.createElement("ScreenGui", nil, {
        Frame = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 8),
            Size = UDim2.new(.2, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Item1 = ItemSlot.new(1),
            Item2 = ItemSlot.new(2),
            ListLayout = Roact.createElement("UIListLayout", {
                SortOrder = Enum.SortOrder.LayoutOrder,
                FillDirection = Enum.FillDirection.Vertical,
            })
        })
    })
end

return Roact.createElement(
    RoactRodux.connect(
        function(state, _)
            return {
                Items = state.Items,
                Selected = state.Selected,
            }
        end
    )(Items)
)