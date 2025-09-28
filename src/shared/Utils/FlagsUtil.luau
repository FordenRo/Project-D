local FlagsUtil = {}

function FlagsUtil.BoolsToFlags(...: boolean): number
	local flags = 0
	for k, v in table.pack(...) do
		if typeof(k) ~= "number" or not v then continue end

		flags += 2 ^ (k - 1)
	end
	return flags
end

function FlagsUtil.FlagsToBools(flags: number, size: number?): ...boolean
	size = size or 8
	assert(size, "")

	local array = table.create(size)
	for i = 0, size - 1 do
		table.insert(array, bit32.band(flags, math.pow(2, i)) ~= 0)
	end
	return array
end

return FlagsUtil
