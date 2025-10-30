local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RF = ReplicatedStorage:WaitForChild("PlayerStatsRF") :: RemoteFunction

local Actions = {
	GetCash = 0,
	GetLaps = 1,
}

local PlayerStatsController = {}
PlayerStatsController.__index = PlayerStatsController

export type PlayerStatsController = {
	GetCash: (self: PlayerStatsController) -> number,
	GetLaps: (self: PlayerStatsController) -> number,
}

function PlayerStatsController.new(): PlayerStatsController
	local self: PlayerStatsController =
		setmetatable({}, PlayerStatsController) :: any

	return self
end

function PlayerStatsController.GetCash(self: PlayerStatsController): number
	return RF:InvokeServer(Actions.GetCash)
end

function PlayerStatsController.GetLaps(self: PlayerStatsController): number
	return RF:InvokeServer(Actions.GetLaps)
end

return PlayerStatsController.new()
