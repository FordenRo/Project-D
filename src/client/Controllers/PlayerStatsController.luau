local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerStatsController = {}
PlayerStatsController.__index = PlayerStatsController

export type PlayerStatsController = typeof(setmetatable({} :: {}, PlayerStatsController))

local remoteFunction = ReplicatedStorage:WaitForChild("PlayerStatsRF") :: RemoteFunction

function PlayerStatsController.new()
	local self: PlayerStatsController = setmetatable({}, PlayerStatsController) :: any

	return self
end

function PlayerStatsController.GetCash(self: PlayerStatsController): number
	return remoteFunction:InvokeServer("GetPlayerCash")
end

return PlayerStatsController.new()
