local Table = {}

function Table.bsearch(t: {any}, cmp: (number) -> number, min: number?, max: number?): number
	min = min or 1
	max = max or #t
	local i = math.floor((min + max) / 2)
	local res = if min == max then 0 else cmp(i)
	if res == 0 then
		return i
	elseif res == 1 then
		return Table.bsearch(t, cmp, min, i-1)
	elseif res == 2 then
		return Table.bsearch(t, cmp, i+1, max)
	end
end

return Table