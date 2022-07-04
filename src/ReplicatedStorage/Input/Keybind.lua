local ContextActionService = game:GetService("ContextActionService")

local Keybind = {}
Keybind.__index = Keybind

export type CASCallback = (string?, Enum.UserInputState, InputObject) -> ()
export type Key = Enum.KeyCode | Enum.UserInputType

function Keybind.new(
	name: string,
	callback: CASCallback,
	mobileButton: boolean?,
	cooldown: number?
)
	local self = setmetatable({}, Keybind)
	self.Name = name
	self.Callback = callback
	self.MobileButton = mobileButton or true
	self.Cooldown = cooldown or 0
	self.Debounce = false
	return self
end

function Keybind:Bind(...: Key)
	ContextActionService:BindAction(self.Name, function(_, ...)
		if not self.Debounce then
			if self.Callback(...) then
				self.Debounce = true
				task.wait(_G.time(self.Cooldown))
				self.Debounce = false
			end
		end
	end, self.MobileButton, ...)
	-- return self so that it can create and bind in one statement
	return self
end

function Keybind:Unbind()
	ContextActionService:UnbindAction(self.Name)
end

return Keybind