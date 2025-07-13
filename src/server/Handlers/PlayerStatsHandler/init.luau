local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local PlayerStatsStore = DataStoreService:GetDataStore("PlayerStats")

local PlayerStatsHandler = {}
PlayerStatsHandler.__index = PlayerStatsHandler

export type PlayerStatsHandler = typeof(setmetatable(
	{} :: {
		PlayerStats: { [Player]: any },
	},
	PlayerStatsHandler
))

function PlayerStatsHandler.new()
	local self = setmetatable({}, PlayerStatsHandler) :: PlayerStatsHandler

	self.PlayerStats = {}
	self.Handlers = {}

	for _, handler in script:GetChildren() do
		if handler:IsA("ModuleScript") then table.insert(self.Handlers, require(handler).new()) end
	end

	Players.PlayerAdded:Connect(function(player) self:OnPlayerAdded(player) end)
	Players.PlayerRemoving:Connect(function(player) self:OnPlayerRemoving(player) end)

	return self
end

function PlayerStatsHandler.OnPlayerAdded(self: PlayerStatsHandler, player: Player)
	self.PlayerStats[player] = PlayerStatsStore:GetAsync(player.UserId) or {}

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local playtime = Instance.new("IntValue")
	playtime.Name = "Hours"
	playtime.Value = self.PlayerStats[player].Playtime or 0
	playtime.Parent = leaderstats

	local laps = Instance.new("IntValue")
	laps.Name = "Laps"
	laps.Value = self.PlayerStats[player].Laps or 0
	laps.Parent = leaderstats

	for _, handler in self.Handlers do
		if handler.OnPlayerAdded then handler:OnPlayerAdded(player, self.PlayerStats[player]) end
	end
end

function PlayerStatsHandler.OnPlayerRemoving(self: PlayerStatsHandler, player: Player)
	for _, handler in self.Handlers do
		if handler.OnPlayerRemoving then handler:OnPlayerRemoving(player, self.PlayerStats[player]) end
	end

	PlayerStatsStore:SetAsync(player.UserId, self.PlayerStats[player])
	self.PlayerStats[player] = nil
end

return PlayerStatsHandler.new()
