local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Packages.Roact)
local RoactRodux = require(ReplicatedStorage.Packages.RoactRodux)

local Panel = Roact.Component:extend("Panel")

function Panel:render()
	local text = ""
	for k, v in pairs(self.props.Stats) do
		text ..= ("%s: %s\n"):format(k, tostring(v))
	end
	return Roact.createElement("Frame", {
		BackgroundColor3 = BrickColor.new("Really black").Color,
		Position = UDim2.fromScale(.1, .1),
		Size = UDim2.fromScale(.8, .8),
	}, {
		Stats = Roact.createElement("TextLabel", {
			TextSize = 16,
			Font = Enum.Font.Gotham,
			TextColor3 = BrickColor.new("Institutional white").Color,
			Text = text,
		}),

		Replay = Roact.createElement("TextButton", {
			BackgroundColor3 = BrickColor.new("Electric blue").Color,
			BackgroundTransparency = .5,
			TextSize = 24,
			Font = Enum.Font.Gotham,
			[Roact.Event.MouseButton1Click] = function()
				self.props.GameManager:Get("Reset"):FireServer()
			end,
		}),

		Quit = Roact.createElement("TextButton", {
			BackgroundColor3 = BrickColor.new("Crimson").Color,
			BackgroundTransparency = .5,
			TextSize = 24,
			Font = Enum.Font.Gotham,
			[Roact.Event.MouseButton1Click] = function()
				self.props.GameManager:Get("Quit"):FireServer()
			end,
		}),
	})
end

return Roact.createElement(
    RoactRodux.connect(
        function(state, _)
            return {
                Stats = state.Stats,
                GameManager = state.GameManager,
            }
        end
    )(Panel)
)