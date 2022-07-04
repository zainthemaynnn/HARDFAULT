-- ez-ness over performance, amirite?

local HTTP = game:GetService("HttpService")

local UniqueCache = {}
UniqueCache.__index = UniqueCache

function UniqueCache.__newindex()
	error("Use `uniqueKey = UniqueCache:Serialize(key, value)`.", 2)
end

function UniqueCache.new()
	local self = setmetatable({}, UniqueCache)
	return self
end

function UniqueCache:Serialize(k, v)
	local nk = ("%s_%i"):format(tostring(k), HTTP:GenerateGUID(false))
	rawset(self, nk, v)
	return nk
end

return UniqueCache