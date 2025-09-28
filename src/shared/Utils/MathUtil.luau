local MathUtil = {}

function MathUtil.Lerp(a: number, b: number, t: number): number return a + (b - a) * t end

function MathUtil.MapToRange(a: number, min: number, max: number): number return (a - min) / (max - min) end

return MathUtil
