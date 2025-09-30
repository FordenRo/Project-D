local StringUtil = {}

local abbreviations = {
	K = 3,
	M = 6,
	B = 9,
	Qa = 12,
} :: { [string]: number }

table.sort(abbreviations, function(a, b) return a > b end)

function StringUtil.AbbreviateNumber(number: number): string
	for k, v in abbreviations do
		local num = number / (10 ^ v)
		if num >= 100 then return string.format("%d %s", math.floor(num), k) end
		if num >= 10 then
			return string.format("%.1f %s", math.floor(num * 10) / 10, k)
		end
		if num >= 1 then
			return string.format("%.2f %s", math.floor(num * 100) / 100, k)
		end
	end
	return tostring(math.floor(number))
end

function StringUtil.SplitPascalCase(s: string): string
	return string.gsub(s, "([A-Za-z])([A-Z][a-z])", "%1 %2")
end

return StringUtil
