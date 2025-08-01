local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local SprintController = {}
SprintController.__index = SprintController

local SPRINT_MULTIPLIER = 1.5

export type SprintController = typeof(setmetatable(
	{} :: {
		Humanoid: Humanoid,
		_WalkSpeed: number,
	},
	SprintController
))

function SprintController.new()
	local self: SprintController = setmetatable({}, SprintController) :: any

	self.Humanoid = player.Character:WaitForChild("Humanoid")
	self._WalkSpeed = self.Humanoid.WalkSpeed

	ContextActionService:BindAction(
		"Sprint",
		function(_, state: Enum.UserInputState) self:ToggleSprint(state == Enum.UserInputState.Begin) end,
		false,
		Enum.KeyCode.LeftShift
	)

	return self
end

function SprintController.ToggleSprint(self: SprintController, state: boolean)
	self.Humanoid.WalkSpeed = self._WalkSpeed * (state and SPRINT_MULTIPLIER or 1)
end

return SprintController.new()
