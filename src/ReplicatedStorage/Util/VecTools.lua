-- various shape drawing methods

local VecTools = {}

function VecTools.rotate(vec: Vector3, angle: number, axis: Vector3?): Vector3
	return CFrame.fromAxisAngle(axis or Vector3.yAxis, angle):VectorToWorldSpace(vec)
end

function VecTools.fromAngle(angle: number, axis: Vector3?): Vector3
	return VecTools.rotate(Vector3.xAxis, angle, axis)
end

function VecTools.polygon(vertices: number, segsize: number): {Vector3}
	local points = table.create(vertices * segsize)
	local pos0, pos1
	for n=1, vertices do
		local a = 2*math.pi/vertices * n
		pos0 = pos1 or VecTools.fromAngle(0)
		pos1 = VecTools.fromAngle(a)
		for i=1, segsize do
			points[#points+1] = pos0:Lerp(pos1, i/segsize)
		end
	end
	return points
end

function VecTools.circle(n: number): {Vector3}
	local points = table.create(n)
	for i=1, n do
		points[#points+1] = VecTools.fromAngle(2*math.pi/n*i)
	end
	return points
end

function VecTools.arc(a: number, n: number, ref: Vector3?): {Vector3}
	ref = ref or -Vector3.zAxis
	if n == 1 then
		return {ref}
	else
		local points = table.create(n)
		local v0 = VecTools.rotate(ref, -a/2)
		for i=0, n-1 do
			points[#points+1] = VecTools.rotate(v0, a/(n-1)*i)
		end
		return points
	end
end

function VecTools.row(n: number): {Vector3}
	return VecTools.line(Vector3.xAxis, -Vector3.xAxis, n)
end

function VecTools.line(pos0: Vector3, pos1: Vector3, n: number): {Vector3}
	local points = table.create(n)
	for i=0, n-1 do
		points[#points+1] = pos0:Lerp(pos1, i/(n-1))
	end
	return points
end

return VecTools