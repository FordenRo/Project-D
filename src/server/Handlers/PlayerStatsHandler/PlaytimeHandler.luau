local PlaytimeHandler = {}
PlaytimeHandler.__index = PlaytimeHandler

export type PlaytimeHandler = typeof(setmetatable(
	{} :: {
		_JoinedTime: { [Player]: number },
	},
	PlaytimeHandler
))

function PlaytimeHandler.new()
	local self = setmetatable({}, PlaytimeHandler) :: PlaytimeHandler

	self._JoinedTime = {}

	return self
end

function PlaytimeHandler.GetPlaytime(self: PlaytimeHandler, player: Player, playerStats: any)
	return tick() - self._JoinedTime[player] + (playerStats.Playtime or 0)
end

function PlaytimeHandler.OnPlayerAdded(self: PlaytimeHandler, player: Player, playerStats: any)
	self._JoinedTime[player] = tick()
	local playtimeValue = (player:FindFirstChild("leaderstats") :: Folder):FindFirstChild("Hours") :: IntValue

	task.spawn(function()
		while player.Parent do
			playtimeValue.Value = self:GetPlaytime(player, playerStats) / 3600
			task.wait(1)
		end
	end)
end

function PlaytimeHandler.OnPlayerRemoving(self: PlaytimeHandler, player: Player, playerStats: any)
	playerStats.Playtime = self:GetPlaytime(player, playerStats)
	self._JoinedTime[player] = nil
end

function PlaytimeHandler:Destroy() end

return PlaytimeHandler
