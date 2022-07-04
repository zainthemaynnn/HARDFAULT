-- this quadtree will find whether parts intersect using spatial query API
-- for this reason, despite being a quadtree, the size.Y and origin.Position.Y actually matter
-- additionally, for sizes not congruent to maxSize, the quadtree will still attempt to find box sizes
-- within the bounds of minSize and maxSize in both dimensions when creating the second layer
-- L1 -> 1, L2 -> varies, L3+ -> 4 | 0
local Quadtree = {}
Quadtree.__index = Quadtree

function Quadtree.new(origin: CFrame, size: Vector3, minSize: number?, maxSize: number?)
	minSize = minSize or 1.0
	maxSize = maxSize or math.max(size.X, size.Z)

	local self = setmetatable({}, Quadtree)
	local X, Y = math.ceil(size.X / maxSize), math.ceil(size.Z / maxSize)

	local subsize = size / Vector3.new(X, 1, Y)

	self.CFrame = origin
	self.Size = size
	self.Children = table.create(X*Y)
	self.Dimensions = Vector2.new(X, Y)
	-- memoized under :Depth()
	self._Depth = nil

	for y=0, Y-1 do
		for x=0, X-1 do
			self.Children[#self.Children+1] = Quadtree.sub(
				origin:PointToWorldSpace(Vector3.new(subsize.X*x, 0, subsize.Z*y) - size/2 + subsize/2),
				subsize,
				minSize
			)
		end
	end

	return self
end

function Quadtree.sub(origin: CFrame, size: Vector3, minSize: number)
	local self = setmetatable({}, Quadtree)

	self.CFrame = origin
	self.Size = size
	self.Children = {}
	self.Dimensions = Vector2.new(2, 2)
	self._Depth = nil

	local subsize = size / Vector3.new(2, 1, 2)

	if subsize.X > minSize and subsize.Z > minSize then
		local function addRegion(pmX: number, pmY: number)
			self.Children[#self.Children+1] =
				Quadtree.sub(origin:PointToWorldSpace(Vector3.new(subsize.X*pmX, 0, subsize.Z*pmY)/2), subsize, minSize)
		end

		addRegion(-1, -1)
		addRegion(1, -1)
		addRegion(-1, 1)
		addRegion(1, 1)
	end

	return self
end

function Quadtree:Intersects(overlapParams: OverlapParams): boolean
	return #game:GetPartBoundsInBox(self.CFrame, self.Size, overlapParams) > 0
end

function Quadtree:Intersecting(overlapParams: OverlapParams, intersecting: {any}?): {any}
	intersecting = intersecting or {}

	if #self.Children == 0 then
		intersecting[#intersecting+1] = self
	else
		for _, child in pairs(self.Children) do
			if child:Intersects(overlapParams) then
				child:Intersecting(overlapParams, intersecting)
			end
		end
	end

	return intersecting
end

function Quadtree:Prune(overlapParams: OverlapParams, pruned: {any}?): {any}
	pruned = pruned or {}

	if #self.Children == 0 then
		return
	else
		for i, child in pairs(self.Children) do
			if child:Intersects(overlapParams) then
				child:Prune(overlapParams, pruned)
			else
				pruned[#pruned+1] = self.Children:remove(i)
			end
		end
	end

	return pruned
end

function Quadtree:Depth(depth: number?): number
	if self._Depth then
		return self._Depth
	else
		depth = depth or 0
		depth += 1
		local res = if #self.Children == 0 then depth else self.Children[1]:Depth(depth)
		self._Depth = res
		return res
	end
end

function Quadtree:Size(): Vector2
	local depth = self:Depth()
	return self.Dimensions * math.pow(4, depth-2)
end

return Quadtree