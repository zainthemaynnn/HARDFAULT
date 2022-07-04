local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Flipper = require(ReplicatedStorage.Packages.Flipper)
local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)
local SFX = require(ReplicatedStorage.Effects.SFX)

local List = Roact.Component:extend("List")

local RESISTANCE_POSITIONING = {
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
}

local VIEWPORT_ROT_SPEED_SEC = (2*math.pi)/12
local HP_ICON = "http://www.roblox.com/asset/?id=3192484653"

function List:init()
    self.Camera = Roact.createRef()
    self.Viewport = Roact.createRef()
    self.CamRotation = Flipper.SingleMotor.new(0)
    local cbinding, csetBinding = Roact.createBinding(self.CamRotation:getValue())
    self.ViewportBinding = cbinding
    self.CamRotation:onStep(csetBinding)

    self.PositionMotor = Flipper.SingleMotor.new(0)
    local pbinding, psetBinding = Roact.createBinding(self.PositionMotor:getValue())
    self.PositionBinding = pbinding
    self.PositionMotor:onStep(psetBinding)
end

function List:willUpdate(newProps)
    if self.props.CurrentEnemy then self.props.CurrentEnemy.Model.Parent = nil end
    if newProps.CurrentEnemy then newProps.CurrentEnemy.Model.Parent = self.Viewport:getValue() end
    self.CamRotation:setGoal(Flipper.Instant.new(0))
    self.CamRotation:step()
    self.CamRotation:setGoal(Flipper.Linear.new(1e6, { velocity = VIEWPORT_ROT_SPEED_SEC })) -- one million should do it

    if newProps.Active then
        self.PositionMotor:setGoal(Flipper.Spring.new(1, {
            frequency = 5.0,
            dampingRatio = 0.75,
        }))
    else
        self.PositionMotor:setGoal(Flipper.Spring.new(0, {
            frequency = 4.0,
            dampingRatio = 0.75,
        }))
    end
end

function List:render()
    local enemyTiles = {}
    local resistances = {}

    for i=1,self.props.EnemiesTotal do
        local enemy = self.props.Enemies[i]
        enemyTiles[tostring(i)] = Roact.createElement("TextButton", {
            Text = table.concat({tostring(i), " ", if enemy then enemy.Name else "???"}),
            TextSize = 18,
            TextColor3 = BrickColor.new("Institutional white").Color,
            Font = Enum.Font.Gotham,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = i,
            BackgroundColor3 = if i == self.props.Selected then BrickColor.new("Dark grey").Color else BrickColor.new("Really black").Color,
            BorderColor3 = BrickColor.new("Dark grey").Color,
            [Roact.Event.MouseButton1Click] = function()
                self.props.Select(i)
            end
        })
    end
    enemyTiles["Layout"] = Roact.createElement("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Vertical,
    })

    if self.props.CurrentEnemy then
        for resistance, value in pairs(self.props.CurrentEnemy.Resistances) do
            local positioning = RESISTANCE_POSITIONING[resistance]
            local weaknessColor =
                if value > 1 then BrickColor.new("Bright green").Color
                elseif value < 0 then BrickColor.new("Bright red").Color
                else BrickColor.new("Institutional white").Color

            resistances[resistance] = Roact.createElement("Frame", {
                Size = UDim2.new(1, 0, 0, 60),
                LayoutOrder = positioning.LayoutOrder,
                BackgroundColor3 = BrickColor.new("Really black").Color,
                BorderSizePixel = 0,
            }, {
                Icon = Roact.createElement("ImageLabel", {
                    Position = UDim2.new(0, 6, 0, 6),
                    Size = UDim2.new(0, 48, 0, 48),
                    Image = positioning.Icon,
                    ImageColor3 = weaknessColor,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }),
                Text = Roact.createElement("TextLabel", {
                    Position = UDim2.new(0, 60, 0, 6),
                    Size = UDim2.new(1, -66, 0, 48),
                    Text = ("%+.f%%"):format(value * 100),
                    TextColor3 = weaknessColor,
                    TextSize = 32,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    Font = Enum.Font.Code,
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                }),
            })
        end
    end

    resistances["Layout"] = Roact.createElement("UIGridLayout", {
        CellSize = UDim2.new(.5, 0, .5, 0),
        CellPadding = UDim2.new(0, 0, 0, 0),
        SortOrder = Enum.SortOrder.LayoutOrder,
        FillDirection = Enum.FillDirection.Horizontal,
    })

    local focus = self.props.CurrentEnemy and self.props.CurrentEnemy.Model.PrimaryPart.CFrame

    return Roact.createElement("ScreenGui", nil, {
        Main = Roact.createElement("Frame", {
            Position = self.PositionBinding:map(function(a)
                return UDim2.new(-.9, 0, .05, 0):Lerp(UDim2.new(.05, 0, .05, 0), a)
            end),
            Size = UDim2.new(.9, 0, .9, 0),
            BackgroundColor3 = BrickColor.new("Really black").Color,
            BackgroundTransparency = .5,
            BorderSizePixel = 0,
        }, {
            List = Roact.createElement("ScrollingFrame", {
                Position = UDim2.new(0, 0, 0, 0),
                Size = UDim2.new(.25, 0, 1, 0),
                ScrollingDirection = Enum.ScrollingDirection.Y,
                BackgroundColor3 = BrickColor.new("Really black").Color,
                BorderSizePixel = 0,
            }, enemyTiles),
            Data = Roact.createElement("Frame", {
                Position = UDim2.new(.25, 0, 0, 0),
                Size = UDim2.new(.75, 0, 1, 0),
                BackgroundTransparency = 1,
            }, {
                Viewport = Roact.createElement("ViewportFrame", {
                    Position = UDim2.new(0, 0, 0, 0),
                    Size = UDim2.new(.6, 0, 1, 0),
                    CurrentCamera = self.Camera,
                    BackgroundTransparency = 1,
                    [Roact.Ref] = self.Viewport,
                }, {
                    Camera = Roact.createElement("Camera", {
                        CFrame = self.ViewportBinding:map(function(v)
                            return focus and CFrame.lookAt(focus.Position + Vector3.new(math.sin(v), 0, -math.cos(v)) * 10, focus.Position) -- eh, works well enough
                        end),
                        [Roact.Ref] = self.Camera,
                    }),
                }),
                Description = Roact.createElement("Frame", {
                    Position = UDim2.new(.6, 0, 0, 0),
                    Size = UDim2.new(.4, 0, 1, 0),
                    BackgroundColor3 = BrickColor.new("Really black").Color,
                    BorderSizePixel = 0,
                }, {
                    HP = Roact.createElement("Frame", {
                        LayoutOrder = 1,
                        Size = UDim2.new(1, 0, 0, 60),
                        BackgroundColor3 = BrickColor.new("Really black").Color,
                        BorderSizePixel = 0,
                    }, {
                        ImageLabel = Roact.createElement("ImageLabel", {
                            Position = UDim2.new(0, 0, 0, 0),
                            Size = UDim2.new(0, 60, 0, 60),
                            Image = HP_ICON,
                            ImageColor3 = BrickColor.new("Institutional white").Color,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                        }),
                        Text = Roact.createElement("TextLabel", {
                            Position = UDim2.new(0, 60, 0, 6),
                            Size = UDim2.new(1, -66, 0, 48),
                            Text = if self.props.CurrentEnemy then self.props.CurrentEnemy.HP else "???",
                            TextColor3 = BrickColor.new("Institutional white").Color,
                            TextSize = 32,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Font = Enum.Font.Code,
                            BackgroundTransparency = 1,
                        }),
                    }),
                    Resistances = Roact.createElement("Frame", {
                        LayoutOrder = 2,
                        Size = UDim2.new(1, 0, 0, 120),
                        BackgroundColor3 = BrickColor.new("Really black").Color,
                        BorderSizePixel = 0,
                    }, resistances),
                    FlavorText = Roact.createElement("Frame", {
                        LayoutOrder = 3,
                        Size = UDim2.new(1, 0, 0, 0),
                        AutomaticSize = Enum.AutomaticSize.Y,
                        BackgroundColor3 = BrickColor.new("Really black").Color,
                        BorderSizePixel = 0,
                    }, {
                        Text = Roact.createElement("TextLabel", {
                            Position = UDim2.fromOffset(6, 6),
                            Size = UDim2.new(1, -12, 0, 0),
                            Text = if self.props.CurrentEnemy then self.props.CurrentEnemy.FlavorText else "???",
                            TextColor3 = BrickColor.new("Institutional white").Color,
                            TextSize = 18,
                            TextXAlignment = Enum.TextXAlignment.Left,
                            Font = Enum.Font.Gotham,
                            AutomaticSize = Enum.AutomaticSize.Y,
                            BackgroundTransparency = 1,
                            BorderSizePixel = 0,
                            TextWrapped = true,
                        })
                    }),
                    Layout = Roact.createElement("UIListLayout", {
                        SortOrder = Enum.SortOrder.LayoutOrder,
                        FillDirection = Enum.FillDirection.Vertical,
                    }),
                }),
            }),
        }),
    })
end

return Roact.createElement(
    RoactRodux.connect(
        function(state, _)
            return {
                Enemies = state.Enemies,
                EnemiesTotal = state.EnemiesTotal,
                Selected = state.Selected,
                CurrentEnemy = state.Enemies[state.Selected],
                Active = state.Active,
            }
        end,
        function(dispatch)
            return {
                Select = function(id: number)
                    dispatch({
                        type = "Select",
                        Selected = id,
                    })
                end
            }
        end
    )(List)
)