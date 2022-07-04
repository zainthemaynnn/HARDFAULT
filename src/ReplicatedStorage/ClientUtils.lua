local ContextActionService = game:GetService("ContextActionService")
local ClientUtils = {}

function ClientUtils.cutsceneify(func)
	-- for now this simply disables controls until the function is done
	local function wrapped(...)
		-- https://devforum.roblox.com/t/how-to-temporarily-disable-all-character-input/178365/2?u=speedmask
		ContextActionService:BindAction(
			"disable_input",
			function()
				return Enum.ContextActionResult.Sink
			end,
			false,
			unpack(Enum.PlayerActions:GetEnumItems())
		)
		func(...)
		ContextActionService:UnbindAction("disable_input")
	end
	return wrapped
end

function ClientUtils.pluralize(word: string)
	-- obviously not complete at all, will update as I go
	-- inefficient too so don't use it anywhere stupid

	assert(#word > 0, "Attempt to pluralize empty string.")
	if #word == 1 then
		return word .. "'s"
	end

	local VOWELS = {"a", "e", "i", "o", "u"}
	local root, final
	local precedingVowel

	local function letterAt(index)
		return word:sub(index, index)
	end

	local function splitAt(index)
		root, final = word:sub(1, index), word:sub(index + 1, -1)
		precedingVowel = table.find(VOWELS, letterAt(#root)) and true or false
	end

	splitAt(-2)
	if final == "s" or (final == "x" and precedingVowel) then
		return word .. "es"
	elseif final == "y" then
		return precedingVowel and word .. "s" or root .. "ies"
	else
		return word .. "s"
	end
end

return ClientUtils