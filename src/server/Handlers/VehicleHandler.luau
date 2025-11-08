local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlayerVehicleType =
	require(ReplicatedStorage.Shared.Types.VehicleTypes.PlayerVehicleType)
local ServerVehicle = require(ServerScriptService.Server.Classes.ServerVehicle)
local TuneType = require(ReplicatedStorage.Shared.Types.VehicleTypes.TuneType)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local RF = Instance.new("RemoteFunction")
RF.Name = "VehicleRF"
RF.Parent = ReplicatedStorage

local RE = Instance.new("RemoteEvent")
RE.Name = "VehicleRE"
RE.Parent = ReplicatedStorage

local Actions = {
	SpawnVehicle = 0,
	RemoveVehicle = 1,
}

--- All spawned vehicles in the workspace
local SpawnedVehicles = {} :: { [Player]: VehicleTypes.ServerVehicle }

local VehicleHandler = {}
VehicleHandler.__index = VehicleHandler

export type VehicleHandler = {
	--- Spawn vehicle
	SpawnVehicle: (
		self: VehicleHandler,
		player: Player
	) -> VehicleTypes.ServerVehicle,
	--- Remove player's spawned vehicle
	RemoveSpawnedVehicle: (self: VehicleHandler, player: Player) -> (),
	--- Returns player's spawned vehicle
	GetPlayerSpawnedVehicle: (
		self: VehicleHandler,
		player: Player
	) -> VehicleTypes.ServerVehicle?,
	GetPlayerVehicles: (
		self: VehicleHandler,
		player: Player
	) -> { PlayerVehicleType.PlayerVehicle },
	GetPlayerVehicleInfo: (
		self: VehicleHandler,
		player: Player,
		id: string
	) -> PlayerVehicleType.PlayerVehicleInfo,
	--- Registering new vehicle and returns ID
	RegisterNewPlayerVehicle: (
		self: VehicleHandler,
		player: Player,
		name: string
	) -> string,
	UpdatePlayerVehicleInfo: (
		self: VehicleHandler,
		player: Player,
		vehicle: VehicleTypes.BaseVehicle
	) -> (),
}

function VehicleHandler.new(): VehicleHandler
	local self: VehicleHandler = setmetatable({}, VehicleHandler) :: any

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Once(function()
			for _, vehicle in SpawnedVehicles do
				RE:FireClient(
					player,
					Actions.SpawnVehicle,
					vehicle.Instance,
					vehicle.Owner
				)
			end
		end)
	end)

	RE.OnServerEvent:Connect(function(player: Player, action: number, ...)
		local callbacks = {
			[Actions.SpawnVehicle] = self.SpawnVehicle,
			[Actions.RemoveVehicle] = self.RemoveSpawnedVehicle,
		} :: { (...any) -> () }
		callbacks[action](self, player, ...)
	end)

	return self
end

function VehicleHandler.SpawnVehicle(self: VehicleHandler, player: Player)
	if not player.Character then return end
	if self:GetPlayerSpawnedVehicle(player) then return end

	local characterCF = player.Character:GetPivot()

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }

	local ray = workspace:Raycast(
		characterCF.Position + characterCF.LookVector * 8 + Vector3.yAxis * 10,
		-Vector3.yAxis * 20,
		params
	)
	if not ray then return end

	local instance = (
		ReplicatedStorage.Vehicles:FindFirstChild("AE-86 Trueno") :: Model
	):Clone()
	instance:PivotTo(
		CFrame.new(ray.Position + Vector3.yAxis * 2, characterCF.LookVector)
	)
	instance.Parent = game.Workspace

	local vehicle = ServerVehicle.new(instance, player)
	SpawnedVehicles[player] = vehicle

	instance.Destroying:Once(function() SpawnedVehicles[player] = nil end)

	RE:FireAllClients(Actions.SpawnVehicle, instance, player)
	return vehicle
end

function VehicleHandler.RemoveSpawnedVehicle(
	self: VehicleHandler,
	player: Player
)
	local vehicle = self:GetPlayerSpawnedVehicle(player)
	if not vehicle then return end

	vehicle:Destroy()
end

function VehicleHandler.GetPlayerSpawnedVehicle(
	self: VehicleHandler,
	player: Player
): VehicleTypes.ServerVehicle?
	return SpawnedVehicles[player]
end

function VehicleHandler.GetPlayerVehicles(
	self: VehicleHandler,
	player: Player
): { PlayerVehicleType.PlayerVehicle }
	return HttpService:JSONDecode(
		DataStoreService:GetDataStore("PlayerVehicles")
			:GetAsync(tostring(player.UserId)) or "{}"
	)
end

function VehicleHandler.GetPlayerVehicleInfo(
	self: VehicleHandler,
	player: Player,
	id: number
): PlayerVehicleType.PlayerVehicleInfo
	return HttpService:JSONDecode(
		(
			DataStoreService:GetDataStore("PlayerVehicles", `info/{id}`)
				:GetAsync(tostring(player.UserId))
		)
	)
end

function VehicleHandler.RegisterNewPlayerVehicle(
	self: VehicleHandler,
	player: Player,
	name: string
)
	local id = HttpService:GenerateGUID()
	local tune =
		require((ReplicatedStorage.Shared.Vehicle.Tunes :: any)[name]) :: TuneType.Tune

	local playerVehInfo = {
		Name = name,
		ID = id,
		Tune = {},
		Fuel = tune.FuelCapacity,
		Mileage = 0,
		EngineHealth = 1,
		-- Deformation = {},
		Wheels = {},
	} :: PlayerVehicleType.PlayerVehicleInfo

	local playerVeh = {
		Name = name,
		ID = id,
	} :: PlayerVehicleType.PlayerVehicle

	DataStoreService:GetDataStore("PlayerVehicles", `info/{id}`)
		:SetAsync(
			tostring(player.UserId),
			HttpService:JSONEncode(playerVehInfo)
		)

	local playerVehicles = self:GetPlayerVehicles(player)
	table.insert(playerVehicles, playerVeh)

	DataStoreService:GetDataStore("PlayerVehicle")
		:SetAsync(
			tostring(player.UserId),
			HttpService:JSONEncode(playerVehicles)
		)

	return id
end

function VehicleHandler.UpdatePlayerVehicleInfo(
	self: VehicleHandler,
	player: Player,
	vehicle: VehicleTypes.BaseVehicle
)
	local playerVehInfo = self:GetPlayerVehicleInfo(player, vehicle.ID)
	playerVehInfo.Fuel = vehicle.Fuel
	playerVehInfo.EngineHealth = vehicle.Engine.Health
	playerVehInfo.Mileage = vehicle.Mileage

	local baseTune = require(
		(ReplicatedStorage.Shared.Vehicle.Tunes :: any)[vehicle.Instance.Name]
	) :: TuneType.Tune
	local tune = {}
	for k, v in vehicle.Tune :: any do
		if v ~= baseTune[k] then tune[k] = v end
	end
	playerVehInfo.Tune = tune

	DataStoreService:GetDataStore("PlayerVehicles", `info/{playerVehInfo.ID}`)
		:SetAsync(
			tostring(player.UserId),
			HttpService:JSONEncode(playerVehInfo)
		)
end

return VehicleHandler.new()
