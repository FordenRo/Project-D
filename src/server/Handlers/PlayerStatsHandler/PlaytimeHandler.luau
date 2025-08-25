local DataStoreService = game:GetService("DataStoreService")

local PlaytimeDataStore = DataStoreService:GetOrderedDataStore("PlayerStats", "Playtime")

local PlaytimeHandler = {}
PlaytimeHandler.__index = PlaytimeHandler

export type PlaytimeHandler = typeof(setmetatable(
	{} :: {
		_JoinedTime: { [Player]: number },
		_PlayerPlaytime: { [Player]: number },
	},
	PlaytimeHandler
))

function PlaytimeHandler.new(): PlaytimeHandler
	local self: PlaytimeHandler = setmetatable({}, PlaytimeHandler) :: any

	self._JoinedTime = {}
	self._PlayerPlaytime = {}

	return self
end

function PlaytimeHandler.GetPlayerPlaytime(self: PlaytimeHandler, player: Player)
	return tick() - self._JoinedTime[player] + self._PlayerPlaytime[player]
end

function PlaytimeHandler.OnPlayerAdded(self: PlaytimeHandler, player: Player)
	self._JoinedTime[player] = tick()
	self._PlayerPlaytime[player] = PlaytimeDataStore:GetAsync(player.UserId) or 0

	local playtimeValue = (player:FindFirstChild("leaderstats") :: Folder):FindFirstChild("Hours") :: IntValue
	task.spawn(function()
		while player.Parent do
			local hours = self:GetPlayerPlaytime(player) / 3600
			if hours < 100 then
				playtimeValue.Value = string.format("%.1f", hours)
			else
				playtimeValue.Value = tostring(math.floor(hours))
			end
			task.wait(1)
		end
	end)
end

function PlaytimeHandler.OnPlayerRemoving(self: PlaytimeHandler, player: Player)
	PlaytimeDataStore:SetAsync(player.UserId, math.floor(self:GetPlayerPlaytime(player)))
	self._JoinedTime[player] = nil
	self._PlayerPlaytime[player] = nil
end

return PlaytimeHandler
