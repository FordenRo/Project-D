local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)

local DAY_TEMPERATURE = 34
local NIGHT_TEMPERATURE = 16

local DAY_BRIGHTNESS = 3
local NIGHT_BRIGHTNESS = 0.1

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
			Lighting.ClockTime += deltaTime / 60

			local t = (1 - math.abs(Lighting.ClockTime - 12) / 12) ^ 2
			Lighting.Brightness = Lerp(DAY_BRIGHTNESS, NIGHT_BRIGHTNESS, t)
			game.Workspace:SetAttribute("GlobalTemperature", Lerp(DAY_TEMPERATURE, NIGHT_TEMPERATURE, t))
		end
	end)

	return self
end

return DatetimeHandler.new()
