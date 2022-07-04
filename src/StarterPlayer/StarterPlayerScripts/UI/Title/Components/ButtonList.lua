local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local MenuButton = require(script.Parent.MenuButton)

local function ButtonList(props)
    return Roact.createElement("ScreenGui", nil, {
        List = Roact.createElement("UIListLayout", {
            FillDirection = Enum.FillDirection.Vertical,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
        }),

        Button0 = MenuButton.new("1"),
        Button1 = MenuButton.new("2"),
        Button2 = MenuButton.new("3"),
        Button3 = MenuButton.new("4"),
    })
end

ButtonList = RoactRodux.connect(
    function(state, _)
        return {}
    end
)(ButtonList)

return Roact.createElement(ButtonList)