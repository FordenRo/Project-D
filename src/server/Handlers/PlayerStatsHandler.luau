local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbbreviateNumber = require(ReplicatedStorage.Shared.Utils.AbbreviateNumber)

local PlayerStatsHandler = {}
PlayerStatsHandler.__index = PlayerStatsHandler

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "PlayerStatsRF"
remoteFunction.Parent = ReplicatedStorage

local playerJoinedTime: { [Player]: number } = {}
local playerPlaytime: { [Player]: number } = {}

export type PlayerStatsHandler = typeof(setmetatable({} :: {}, PlayerStatsHandler))

function PlayerStatsHandler.new(): PlayerStatsHandler
	local self: PlayerStatsHandler = setmetatable({}, PlayerStatsHandler) :: any

	Players.PlayerAdded:Connect(function(player) OnPlayerAdded(self, player) end)
	Players.PlayerRemoving:Connect(function(player) OnPlayerRemoving(self, player) end)
	remoteFunction.OnServerInvoke = function(player: Player, event: string, ...) return self[event](self, player, ...) end

	return self
end

function OnPlayerAdded(self: PlayerStatsHandler, player: Player)
	playerJoinedTime[player] = tick()
	playerPlaytime[player] = DataStoreService:GetOrderedDataStore("PlayerStats", "Playtime"):GetAsync(player.UserId)

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

	cash.Value = AbbreviateNumber(self:GetPlayerCash(player))
	laps.Value = AbbreviateNumber(self:GetPlayerLaps(player))

	task.defer(function()
		while player.Parent do
			local hours = self:GetPlayerPlaytime(player) / 3600
			if hours < 100 then
				playtime.Value = string.format("%.1f", hours)
			else
				playtime.Value = tostring(math.floor(hours))
			end
			task.wait(1)
		end
	end)
end

function OnPlayerRemoving(self: PlayerStatsHandler, player: Player)
	DataStoreService:GetOrderedDataStore("PlayerStats", "Playtime")
		:SetAsync(player.UserId, math.floor(self:GetPlayerPlaytime(player)))
	playerJoinedTime[player] = nil
	playerPlaytime[player] = nil
end

function PlayerStatsHandler.GetPlayerCash(self: PlayerStatsHandler, player: Player)
	return DataStoreService:GetOrderedDataStore("PlayerStats", "Cash"):GetAsync(player.UserId) or 5000000
end

function PlayerStatsHandler.SetPlayerCash(self: PlayerStatsHandler, player: Player, cash: number)
	DataStoreService:GetOrderedDataStore("PlayerStats", "Cash"):SetAsync(player.UserId, cash)

	local leaderstats = player:FindFirstChild("leaderstats") :: Folder
	leaderstats.Cash.Value = AbbreviateNumber(cash)
end

function PlayerStatsHandler.GetPlayerLaps(self: PlayerStatsHandler, player: Player)
	return DataStoreService:GetOrderedDataStore("PlayerStats", `Laps/{game.PlaceId}`):GetAsync(player.UserId) or 0
end

function PlayerStatsHandler.AddPlayerLap(self: PlayerStatsHandler, player: Player)
	local laps = DataStoreService:GetOrderedDataStore("PlayerStats", `Laps/{game.PlaceId}`)
		:IncrementAsync(player.UserId)

	local leaderstats = player:FindFirstChild("leaderstats") :: Folder
	leaderstats.Laps.Value = AbbreviateNumber(laps)

	return laps
end

function PlayerStatsHandler.GetPlayerPlaytime(self: PlayerStatsHandler, player: Player)
	return tick() - playerJoinedTime[player] + playerPlaytime[player]
end

return PlayerStatsHandler.new()
