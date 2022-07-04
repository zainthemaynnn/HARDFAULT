-- CEnum -> Custom Enum

local EnumData = {}
EnumData.__index = EnumData

local USAGE = "Enum data format: {number, string, value(?)}"

local Enum = {}

local ActualEnum = {}
ActualEnum.__index = ActualEnum

function ActualEnum:Options()
	local opts = {}
	for k, opt in pairs(self) do
		if typeof(k) == "string" then
			opts[#opts+1] = opt
		end
	end
	return opts
end

function Enum.new(options)
	assert(type(options) == "table", "Expected list of `EnumData`. " .. USAGE)
	local enum = setmetatable({}, ActualEnum)

	for i, data in pairs(options) do
		xpcall(
			function()
				assert(type(data) == "table", USAGE)
				local index, key, value = table.unpack(data)
				local v = value or key
				enum[index] = v
				enum[key] = v
			end,

			function()
				error(("Entry %i; "):format(i))
			end
		)
	end

	return enum
end

function Enum:Build(name: string, options)
	assert(not self[name], "Enum already exists.")
	local enum = self.new(options)
	Enum[name] = enum
	return enum
end

-- build from child modules, if any
for _, child in pairs(script:GetChildren()) do
	Enum:Build(child.Name, require(child))
end

return Enum