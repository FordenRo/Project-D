--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

local player = Players.LocalPlayer

local SPRINT_MULTIPLIER = 1.5

local SprintController = {}
SprintController.__index = SprintController

export type SprintController = {}

type SprintControllerImpl = {
	humanoid: Humanoid?,
} & SprintController

function SprintController.new(): SprintController
	local self: SprintControllerImpl = setmetatable({}, SprintController) :: any

	player.CharacterAdded:Connect(
		function()
			self.humanoid = (player.Character :: Model):WaitForChild(
					"Humanoid"
				) :: Humanoid
		end
	)
	if player.Character then
		self.humanoid = player.Character:WaitForChild("Humanoid") :: Humanoid
	end

	ReplicatedStorage.Input.Player.Sprint.StateChanged:Connect(function(value)
		if not self.humanoid then return end

		self.humanoid.WalkSpeed = StarterPlayer.CharacterWalkSpeed
			* (value and SPRINT_MULTIPLIER or 1)
	end)

	return self
end

return SprintController.new()
