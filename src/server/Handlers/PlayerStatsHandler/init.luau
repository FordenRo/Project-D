local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local PlaytimeHandler = require(script.PlaytimeHandler)

local PlayerStatsHandler = {}
PlayerStatsHandler.__index = PlayerStatsHandler

export type PlayerStatsHandler = typeof(setmetatable(
	{} :: {
		PlaytimeHandler: PlaytimeHandler.PlaytimeHandler,
	},
	PlayerStatsHandler
))

function PlayerStatsHandler.new()
	local self = setmetatable({}, PlayerStatsHandler) :: PlayerStatsHandler

	self.PlaytimeHandler = PlaytimeHandler.new()

	Players.PlayerAdded:Connect(function(player) self:OnPlayerAdded(player) end)
	Players.PlayerRemoving:Connect(function(player) self:OnPlayerRemoving(player) end)

	return self
end

function PlayerStatsHandler.OnPlayerAdded(self: PlayerStatsHandler, player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local playtime = Instance.new("StringValue")
	playtime.Name = "Hours"
	playtime.Value = "-"
	playtime.Parent = leaderstats

	local laps = Instance.new("StringValue")
	laps.Name = "Laps"
	laps.Value = "-"
	laps.Parent = leaderstats

	self.PlaytimeHandler:OnPlayerAdded(player)
end

function PlayerStatsHandler.OnPlayerRemoving(self: PlayerStatsHandler, player: Player)
	self.PlaytimeHandler:OnPlayerRemoving(player)
end

return PlayerStatsHandler.new()
