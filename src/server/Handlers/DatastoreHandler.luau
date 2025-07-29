local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultControls = require(ReplicatedStorage.Shared.Vehicle.DefaultControls)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

local DatastoreHandler = {}
DatastoreHandler.__index = DatastoreHandler

export type DatastoreHandler = typeof(setmetatable({} :: {}, DatastoreHandler))

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "DatastoreRF"
remoteFunction.Parent = ReplicatedStorage.Remotes

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "DatastoreRE"
remoteEvent.Parent = ReplicatedStorage.Remotes

function DatastoreHandler.new()
	local self: DatastoreHandler = setmetatable({}, DatastoreHandler) :: any

	return self
end

function DatastoreHandler.Initialize(self: DatastoreHandler)
	local getTypes = {}
	local setTypes = {}

	getTypes.Controls = function(player) return self:GetPlayerControls(player) end
	setTypes.Controls = function(player, value) self:SetPlayerControls(player, value) end

	remoteFunction.OnServerInvoke = function(player: Player, type: string)
		if not getTypes[type] then return end

		return getTypes[type](player)
	end

	remoteEvent.OnServerEvent:Connect(function(player, type: string, value: any)
		if not setTypes[type] then return end

		setTypes[type](player, value)
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
