local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer

local SPRINT_MULTIPLIER = 1.5

local SprintController = {}
SprintController.__index = SprintController

export type SprintController = typeof(setmetatable(
	{} :: {
		Humanoid: Humanoid?,
	},
	SprintController
))

function SprintController.new()
	local self: SprintController = setmetatable({}, SprintController) :: any

	player.CharacterAdded:Connect(function() self.Humanoid = player.Character:WaitForChild("Humanoid") end)
	if player.Character then self.Humanoid = player.Character:WaitForChild("Humanoid") end

	ReplicatedStorage.Input.Player.Sprint.StateChanged:Connect(function(value)
		if not self.Humanoid then return end

		self.Humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed * (value and SPRINT_MULTIPLIER or 1)
	end)

	return self
end

return SprintController.new()
