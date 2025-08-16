local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer

local SprintController = {}
SprintController.__index = SprintController

local SPRINT_MULTIPLIER = 1.5

export type SprintController = typeof(setmetatable(
	{} :: {
		Humanoid: Humanoid?,
	},
	SprintController
))

function SprintController.new()
	local self: SprintController = setmetatable({}, SprintController) :: any

	player.CharacterAdded:Connect(function() self.Humanoid = player.Character:WaitForChild("Humanoid") end)

	ContextActionService:BindAction(
		"Sprint",
		function(_, state: Enum.UserInputState) self:ToggleSprint(state == Enum.UserInputState.Begin) end,
		false,
		Enum.KeyCode.LeftShift
	)

	return self
end

function SprintController.ToggleSprint(self: SprintController, state: boolean)
	if not self.Humanoid then return end

	self.Humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed * (state and SPRINT_MULTIPLIER or 1)
end

return SprintController.new()
