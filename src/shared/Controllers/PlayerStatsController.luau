--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RF = ReplicatedStorage:WaitForChild("PlayerStatsRF") :: RemoteFunction

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
	return RF:InvokeServer("GetPlayerCash")
end

function PlayerStatsController.GetLaps(self: PlayerStatsController): number
	return RF:InvokeServer("GetPlayerLaps")
end

return PlayerStatsController.new()
