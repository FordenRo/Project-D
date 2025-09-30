local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return TableUtil.DeepFreeze({
	{
		Context = "Player",
		Actions = {
			"Sprint",
			"Interact",
		},
	},
	{
		Context = "Vehicle",
		Actions = {
			"Throttle",
			"Brake",
			"TurnLeft",
			"TurnRight",
			"ControllerSteering",
			"Clutch",
			"ShiftUp",
			"ShiftDown",
			"Ignition",
			"Handbrake",
			"Leave",
			"ToggleMouseSteering",
			"ToggleFirstPersonView",
			"TransmissionMode",
			"Lights",
			"LeftTurnSignal",
			"Hazards",
			"RightTurnSignal",
			"Horn",
			"TCS",
			"ABS",
			"CS",
		},
	},
})
