local ServerScriptService = game:GetService("ServerScriptService")

local DatastoreHandler = require(ServerScriptService.Server.Handlers.DatastoreHandler)

local PlaytimeHandler = {}
PlaytimeHandler.__index = PlaytimeHandler

export type PlaytimeHandler = typeof(setmetatable(
	{} :: {
		_JoinedTime: { [Player]: number },
		_PlayerHours: { [Player]: number },
	},
	PlaytimeHandler
))

function PlaytimeHandler.new()
	local self = setmetatable({}, PlaytimeHandler) :: PlaytimeHandler

	self._JoinedTime = {}
	self._PlayerHours = {}

	return self
end

function PlaytimeHandler.GetPlayerPlaytime(self: PlaytimeHandler, player: Player)
	return tick() - self._JoinedTime[player] + self._PlayerHours[player]
end

function PlaytimeHandler.OnPlayerAdded(self: PlaytimeHandler, player: Player)
	self._JoinedTime[player] = tick()
	self._PlayerHours[player] = DatastoreHandler:GetPlayerHours(player)

	local playtimeValue = (player:FindFirstChild("leaderstats") :: Folder):FindFirstChild("Hours") :: IntValue
	task.spawn(function()
		while player.Parent do
			playtimeValue.Value = self:GetPlayerPlaytime(player) / 3600
			task.wait(1)
		end
	end)
end

function PlaytimeHandler.OnPlayerRemoving(self: PlaytimeHandler, player: Player)
	DatastoreHandler:SetPlayerHours(player, self:GetPlayerPlaytime(player))
	self._JoinedTime[player] = nil
	self._PlayerHours[player] = nil
end

return PlaytimeHandler
