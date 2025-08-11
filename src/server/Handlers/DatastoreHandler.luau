local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultControls = require(ReplicatedStorage.Shared.Vehicle.DefaultControls)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local DatastoreHandler = {}
DatastoreHandler.__index = DatastoreHandler

export type DatastoreHandler = typeof(setmetatable({} :: {}, DatastoreHandler))

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "DatastoreRF"
remoteFunction.Parent = ReplicatedStorage

local remoteEvent = Instance.new("RemoteEvent")
remoteEvent.Name = "DatastoreRE"
remoteEvent.Parent = ReplicatedStorage

function DatastoreHandler.new()
	local self = setmetatable({}, DatastoreHandler) :: DatastoreHandler

	self:Initialize()

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

function DatastoreHandler.GetPlayerControls(self: DatastoreHandler, player: Player): VehicleTypes.VehicleControls
	local controls = DefaultControls

	local data = DataStoreService:GetDataStore("PlayerSettings", "Controls"):GetAsync(player.UserId)
	if data then
		for k, v in HttpService:JSONDecode(data) do
			controls[k] = v
			if typeof(v) == "string" then
				local hasKeyCode, keyCode = pcall(function() return Enum.KeyCode[v] end)
				local hasInputType, inputType = pcall(function() return Enum.UserInputType[v] end)
				if hasKeyCode then
					controls[k] = keyCode
				elseif hasInputType then
					controls[k] = inputType
				end
			end
		end
	end

	return controls
end

function DatastoreHandler.SetPlayerControls(self: DatastoreHandler, player: Player, value: VehicleTypes.VehicleControls)
	for k, v in value do
		if typeof(v) == "EnumItem" then value[k] = v.Name end
	end

	DataStoreService:GetDataStore("PlayerSettings", "Controls"):SetAsync(player.UserId, HttpService:JSONEncode(value))
end

function DatastoreHandler.GetPlayerPlaytime(self: DatastoreHandler, player: Player): number
	return DataStoreService:GetOrderedDataStore("PlayerStats", "Playtime"):GetAsync(player.UserId) or 0
end

function DatastoreHandler.SetPlayerPlaytime(self: DatastoreHandler, player: Player, value: number)
	DataStoreService:GetOrderedDataStore("PlayerStats", "Playtime"):SetAsync(player.UserId, math.floor(value))
end

return DatastoreHandler.new()
