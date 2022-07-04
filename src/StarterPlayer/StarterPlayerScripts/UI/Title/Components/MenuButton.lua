local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local Hooks = require(ReplicatedStorage.Packages.Hooks)
local Flipper = require(ReplicatedStorage.Packages.Flipper)
local RoactFlipper = require(ReplicatedStorage.Packages.RoactFlipper)

local MenuButton = {}
MenuButton.__index = MenuButton

function MenuButton.new(text: string)
    return Roact.createElement(
        Hooks.new(Roact)(function(_, hooks)
            return Roact.createElement(
                RoactRodux.connect(
                    function(state, _)
                        return {
                            MenuButton = state.MenuButton,
                        }
                    end
                )(function(props)
                    local textHook = hooks.useValue(text).value
                    local motor = RoactFlipper.useMotor(hooks, 0)
                    local binding = RoactFlipper.getBinding(motor)

                    return Roact.createElement("TextButton", {
                        Text = textHook,
                        Size = binding:map(function(alpha)
                            return UDim2.fromScale(.2, .2):Lerp(UDim2.fromScale(.3, .2), alpha)
                        end),
                        [Roact.Event.MouseEnter] = function()
                            motor:setGoal(Flipper.Spring.new(1, {
                                frequency = 5,
                                dampingRatio = 1,
                            }))
                        end,
                        [Roact.Event.MouseLeave] = function()
                            motor:setGoal(Flipper.Spring.new(0, {
                                frequency = 4,
                                dampingRatio = 0.75,
                            }))
                        end,
                    })
                end)
            )
        end)
    )
end

return MenuButton