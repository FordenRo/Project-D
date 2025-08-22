local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbbreviateNumber = require(ReplicatedStorage.Shared.Utils.AbbreviateNumber)
local PlaytimeHandler = require(script.PlaytimeHandler)

local PlayerStatsHandler = {}
PlayerStatsHandler.__index = PlayerStatsHandler

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "PlayerStatsRF"
remoteFunction.Parent = ReplicatedStorage

export type PlayerStatsHandler = typeof(setmetatable(
	{} :: {
		PlaytimeHandler: PlaytimeHandler.PlaytimeHandler,
	},
	PlayerStatsHandler
))

function PlayerStatsHandler.new()
	local self: PlayerStatsHandler = setmetatable({}, PlayerStatsHandler) :: any

	self.PlaytimeHandler = PlaytimeHandler.new()

	Players.PlayerAdded:Connect(function(player) OnPlayerAdded(self, player) end)
	Players.PlayerRemoving:Connect(function(player) OnPlayerRemoving(self, player) end)
	remoteFunction.OnServerInvoke = function(player: Player, event: string, ...) return self[event](self, player, ...) end

	return self
end

function OnPlayerAdded(self: PlayerStatsHandler, player: Player)
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

	local cash = Instance.new("StringValue")
	cash.Name = "Cash"
	cash.Value = "-"
	cash.Parent = leaderstats

	self.PlaytimeHandler:OnPlayerAdded(player)

	cash.Value = AbbreviateNumber(self:GetPlayerCash(player))
	laps.Value = AbbreviateNumber(self:GetPlayerLaps(player))
end

function OnPlayerRemoving(self: PlayerStatsHandler, player: Player) self.PlaytimeHandler:OnPlayerRemoving(player) end

function PlayerStatsHandler.GetPlayerCash(self: PlayerStatsHandler, player: Player)
	return DataStoreService:GetOrderedDataStore("PlayerStats", "Cash"):GetAsync(player.UserId) or 5000000
end

function PlayerStatsHandler.SetPlayerCash(self: PlayerStatsHandler, player: Player, cash: number)
	DataStoreService:GetOrderedDataStore("PlayerStats", "Cash"):SetAsync(player.UserId, cash)
	player.leaderstats.Cash.Value = AbbreviateNumber(cash)
end

function PlayerStatsHandler.GetPlayerLaps(self: PlayerStatsHandler, player: Player)
	return DataStoreService:GetOrderedDataStore("PlayerStats", `Laps/{game.PlaceId}`):GetAsync(player.UserId) or 0
end

function PlayerStatsHandler.AddPlayerLap(self: PlayerStatsHandler, player: Player)
	local laps = DataStoreService:GetOrderedDataStore("PlayerStats", `Laps/{game.PlaceId}`)
		:IncrementAsync(player.UserId)
	player.leaderstats.Laps.Value = AbbreviateNumber(laps)
	return laps
end

return PlayerStatsHandler.new()
