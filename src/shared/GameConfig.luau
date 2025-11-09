local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RunService = game:GetService("RunService")

local GameConfigType = require(ReplicatedStorage.Shared.Types.GameConfigType)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

local Config = {} :: GameConfigType.GameConfig

Config.Version = `0.0.1`
	.. (
		RunService:IsStudio() and `-STUDIO`
		or `-prealpha ({game.PlaceVersion})`
	)

Config.Changelog = {}

Config.Welcome = `<font size="24">Welcome to <font color="#ffaaaa"><b>Project D:</b></font>`
	.. ` <font size="22"><i>Driving Masters</i></font></font>`
	.. `\n\n`
	.. `This game is a <i>racing simulator</i> that tries to replicate the behaviour of a <i>real</i> car.`
	.. ` Here you can customize your car for drifting, drag racing, touge, <font transparency="0.1"><i>or keep it stock</i></font>.`
	.. `\n\n`
	.. `<b>Features:</b>\n`
	.. `	· Tires can wear\n`
	.. `	· Engine health system\n`
	.. `	· Realistic sound effects\n`
	.. `	· First person view\n`
	.. `	· Detailed cars\n`
	.. `	and more!`
	.. `\n\n`
	.. `<font transparency="0.1">Current version: <i>{Config.Version}</i></font>`

return TableUtil.DeepFreeze(Config)
