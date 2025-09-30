local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)

local DAY_TEMPERATURE = 34
local NIGHT_TEMPERATURE = 16

local DAY_BRIGHTNESS = 3
local NIGHT_BRIGHTNESS = 1

local DatetimeHandler = {}
DatetimeHandler.__index = DatetimeHandler

export type DatetimeHandler = typeof(setmetatable({} :: {}, DatetimeHandler))

function DatetimeHandler.new(): DatetimeHandler
	local self: DatetimeHandler = setmetatable({}, DatetimeHandler) :: any

	Lighting.ClockTime = 12
	Lighting.Brightness = 3
	game.Workspace:SetAttribute("GlobalTemperature", DAY_TEMPERATURE)

	task.spawn(function()
		while true do
			local deltaTime = task.wait(1 / 10)

			if math.abs(Lighting.ClockTime - 12) > 5 then
				Lighting.ClockTime += deltaTime / 60
			else
				Lighting.ClockTime += deltaTime / 120
			end

			local t = (1 - math.abs(Lighting.ClockTime - 12) / 12) ^ 2
			Lighting.Brightness =
				MathUtil.Lerp(NIGHT_BRIGHTNESS, DAY_BRIGHTNESS, t)
			game.Workspace:SetAttribute(
				"GlobalTemperature",
				MathUtil.Lerp(DAY_TEMPERATURE, NIGHT_TEMPERATURE, t)
			)
		end
	end)

	return self
end

return DatetimeHandler.new()
