local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultControls = require(ReplicatedStorage.Shared.Vehicle.DefaultControls)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

local DatastoreHandler = {}
DatastoreHandler.__index = DatastoreHandler

export type DatastoreHandler = typeof(setmetatable({} :: {}, DatastoreHandler))

local remote = Instance.new("RemoteFunction")
remote.Name = "DatastoreRemote"
remote.Parent = ReplicatedStorage.Remotes

function DatastoreHandler.new()
	local self: DatastoreHandler = setmetatable({}, DatastoreHandler) :: any

	return self
end

function DatastoreHandler.Initialize(self: DatastoreHandler)
	local types = {}

	types.Controls = function(player) return self:GetPlayerControls(player) end

	remote.OnServerEvent:Connect(function(player, type: string)
		if not types[type] then return end

		return types[type](player)
	end)
end

function DatastoreHandler.GetPlayerControls(self: DatastoreHandler, player: Player): Types.VehicleControls
	local controls = DefaultControls

	local playerControls = DataStoreService:GetDataStore("PlayerSettings", "Controls"):GetAsync(player.UserId)
	if playerControls then
		for k, v in playerControls do
			controls[k] = v
		end
	end

	return controls
end

function DatastoreHandler.SetPlayerControls(self: DatastoreHandler, player: Player, value: Types.VehicleControls)
	DataStoreService:GetDataStore("PlayerSettings", "Controls"):SetAsync(player.UserId, value)
end

function DatastoreHandler.GetPlayerHours(self: DatastoreHandler, player: Player): number
	return DataStoreService:GetOrderedDataStore("PlayerStats", "Hours"):GetAsync(player.UserId) or 0
end

function DatastoreHandler.SetPlayerHours(self: DatastoreHandler, player: Player, value: number)
	DataStoreService:GetOrderedDataStore("PlayerStats", "Hours"):SetAsync(player.UserId, value)
end

return DatastoreHandler.new()
