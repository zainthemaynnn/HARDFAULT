local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local SFX = require(ReplicatedStorage.Effects.SFX)

local ItemSlot = Roact.Component:extend("ItemSlot")

local CHARACTERISTIC_POSITIONING = {
    Ballistic = {
        Icon = "http://www.roblox.com/asset/?id=748227937",
        LayoutOrder = 1,
    },
    Energy = {
        Icon = "http://www.roblox.com/asset/?id=9279335439",
        LayoutOrder = 2,
    },
    Chemical = {
        Icon = "http://www.roblox.com/asset/?id=6671508785",
        LayoutOrder = 3,
    },
    Fire = {
        Icon = "http://www.roblox.com/asset/?id=8511403112",
        LayoutOrder = 4,
    },
    Heal = {
        Icon = "rbxassetid://541664773",
        LayoutOrder = 5,
    },
    MaxHP = {
        Icon = "rbxassetid://3192484659",
        LayoutOrder = 6,
    },
    Haste = {
        Icon = "rbxassetid://4290007665",
        LayoutOrder = 7,
    },
}

local WHITE = BrickColor.new("Institutional white").Color
local BLACK = BrickColor.new("Really black").Color

function ItemSlot:render()
    local descriptors = {}
    for ch, data in pairs(self.props.Characteristics) do
        local withDuration = data.Duration ~= nil
        local positioning = CHARACTERISTIC_POSITIONING[ch]
        if not positioning then return end
        descriptors[ch] = Roact.createElement("Frame", {
            LayoutOrder = positioning.LayoutOrder,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Icon = Roact.createElement("ImageLabel", {
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(0, 24, 0, 24),
                Image = positioning.Icon,
                ImageColor3 = if self.props.Selected then BLACK else WHITE,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }),
            Text = Roact.createElement("TextLabel", {
                Position = UDim2.new(0, 32, 0, 0),
                AutomaticSize = Enum.AutomaticSize.XY,
                Text = if withDuration then ("%d/%ds"):format(data.Value, data.Duration) else tostring(data.Value),
                TextSize = 24,
                TextXAlignment = Enum.TextXAlignment.Right,
                TextColor3 = if self.props.Selected then BLACK else WHITE,
                    Font = Enum.Font.Code,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }),
        })
    end
    descriptors["Layout"] = Roact.createElement("UIGridLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
        CellSize = UDim2.new(.5, -10, .5, -10),
    })

    return Roact.createElement("Frame", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(0, 0, 0, 0),
        Size = UDim2.new(1, 0, 0, 80),
        BackgroundColor3 = if self.props.Selected then WHITE else BLACK,
        BorderSizePixel = 0,
        LayoutOrder = self.props.Slot,
        ZIndex = 0,
    }, {
        Data = Roact.createElement("Frame", {
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, 0, 0, 0),
            Size = UDim2.new(.8, 0, 1, 80),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        }, {
            Name = Roact.createElement("TextLabel", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, 0, 0, 0),
                Size = UDim2.new(1, 0, 0, 0),
                AutomaticSize = Enum.AutomaticSize.Y,
                Text = self.props.Name .. (if self.props.Weight then " - " .. self.props.Weight .. " dmg" else "")
                    .. if self.props.Clip then (" %d/%d"):format(self.props.Clip.Value, self.props.Clip.Capacity) else "",
                TextColor3 = if self.props.Selected then BLACK else WHITE,
                TextSize = 16,
                TextXAlignment = Enum.TextXAlignment.Right,
                Font = Enum.Font.Code,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }),
            Descriptors = Roact.createElement("Frame", {
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -8, 0, 24),
                Size = UDim2.new(1, -8, 0, 64),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
            }, descriptors),
        }),

        Gradient = Roact.createElement("UIGradient", {
            Transparency = NumberSequence.new(0, 1),
            Rotation = 180.0
        }),
    })
end

function ItemSlot.new(slot: number)
    return Roact.createElement(
        RoactRodux.connect(
            function(state, _)
                local item = state.Items[slot]
                local characteristics = {}
                if item then
                    for affinity, value in pairs(item.Damage or {}) do
                        if affinity ~= "Weight" then
                            characteristics[affinity] = {
                                Value = value,
                            }
                        end
                    end
                end
                return {
                    Name = if item then item.Name else "Empty",
                    Weight = if item and item.Damage then item.Damage.Weight else nil,
                    Characteristics = characteristics,
                    Slot = slot,
                    Selected = state.Selected == slot,
                    Clip = item and item.Clip,
                }
            end
        )(ItemSlot)
    )
end

return ItemSlot