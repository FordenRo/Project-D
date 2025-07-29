local Lighting = game:GetService("Lighting")

local DatetimeHandler = {}
DatetimeHandler.__index = DatetimeHandler

export type DatetimeHandler = typeof(setmetatable({} :: {}, DatetimeHandler))

function DatetimeHandler.new()
	local self = setmetatable({}, DatetimeHandler)

	task.spawn(function()
		while true do
			local deltaTime = task.wait(1)
			Lighting.ClockTime += deltaTime / 60
			Lighting.Brightness = 3 * (1 - math.abs(Lighting.ClockTime - 12) / 12) ^ 2
		end
	end)

	return self
end

return DatetimeHandler.new()
