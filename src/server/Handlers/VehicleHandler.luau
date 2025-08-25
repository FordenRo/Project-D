local CollectionService = game:GetService("CollectionService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ServerVehicle = require(ServerScriptService.Server.Classes.ServerVehicle)
local Tune = require(ReplicatedStorage.Shared.Types.VehicleTypes.Tune)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local VehicleHandler = {}
VehicleHandler.__index = VehicleHandler

export type VehicleHandler = typeof(setmetatable({} :: {}, VehicleHandler))

local remoteFunction = Instance.new("RemoteFunction")
remoteFunction.Name = "VehicleRF"
remoteFunction.Parent = ReplicatedStorage

function VehicleHandler.new(): VehicleHandler
	local self: VehicleHandler = setmetatable({}, VehicleHandler) :: any

	for _, vehicle in CollectionService:GetTagged("Vehicle") do
		if not vehicle:IsDescendantOf(game.Workspace) then continue end

		ServerVehicle.new(vehicle)
	end

	CollectionService:GetInstanceAddedSignal("Vehicle"):Connect(function(vehicle)
		if not vehicle:IsDescendantOf(game.Workspace) then return end

		ServerVehicle.new(vehicle)
	end)

	remoteFunction.OnServerInvoke = function(player: Player, event: string, ...) return self[event](self, player, ...) end

	return self
end

function VehicleHandler.GetPlayerVehicles(self: VehicleHandler, player: Player): { VehicleTypes.PlayerVehicle }
	return HttpService:JSONDecode(DataStoreService:GetDataStore("PlayerVehicles"):GetAsync(player.UserId) or "{}")
end

function VehicleHandler.GetPlayerVehicleInfo(
	self: VehicleHandler,
	player: Player,
	id: number
): VehicleTypes.PlayerVehicleInfo
	return HttpService:JSONDecode(DataStoreService:GetDataStore("PlayerVehicles", `info/{id}`):GetAsync(player.UserId))
end

function VehicleHandler.RegisterNewPlayerVehicle(self: VehicleHandler, player: Player, name: string)
	local id = HttpService:GenerateGUID()
	local tune = require(ReplicatedStorage.Shared.Vehicle.Tunes[name]) :: Tune.Tune

	local playerVehInfo = {
		Name = name,
		ID = id,
		Tune = {},
		Fuel = tune.FuelCapacity,
		Mileage = 0,
		EngineHealth = 1,
		Deformation = {},
		Wheels = {},
	} :: VehicleTypes.PlayerVehicleInfo

	local playerVeh = {
		Name = name,
		ID = id,
	} :: VehicleTypes.PlayerVehicle

	DataStoreService:GetDataStore("PlayerVehicles", `info/{id}`)
		:SetAsync(player.UserId, HttpService:JSONEncode(playerVehInfo))

	local playerVehicles = self:GetPlayerVehicles(player)
	table.insert(playerVehicles, playerVeh)

	DataStoreService:GetDataStore("PlayerVehicle"):SetAsync(player.UserId, HttpService:JSONEncode(playerVehicles))

	return id
end

function VehicleHandler.UpdatePlayerVehicleInfo(self: VehicleHandler, player: Player, vehicle: VehicleTypes.BaseVehicle)
	local playerVehInfo = self:GetPlayerVehicleInfo(player, vehicle.ID)
	playerVehInfo.Fuel = vehicle.Fuel
	playerVehInfo.EngineHealth = vehicle.Engine.Health
	playerVehInfo.Mileage = vehicle.Mileage

	local baseTune = require(ReplicatedStorage.Shared.Vehicle.Tunes[vehicle.Instance.Name]) :: VehicleTypes.Tune
	local tune = {}
	for k, v in vehicle.Tune :: any do
		if v ~= baseTune[k] then tune[k] = v end
	end
	playerVehInfo.Tune = tune

	DataStoreService:GetDataStore("PlayerVehicles", `info/{playerVehInfo.ID}`)
		:SetAsync(player.UserId, HttpService:JSONEncode(playerVehInfo))
end

return VehicleHandler.new()
