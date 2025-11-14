local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientVehicle = require(ReplicatedStorage.Shared.Classes.ClientVehicle)
local Component = require(ReplicatedStorage.Shared.Classes.Component)
local PlayerVehicleType =
	require(ReplicatedStorage.Shared.Types.VehicleTypes.PlayerVehicleType)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local RF = ReplicatedStorage:WaitForChild("VehicleRF") :: RemoteFunction
local RE = ReplicatedStorage:WaitForChild("VehicleRE") :: RemoteEvent

local Actions = {
	SpawnVehicle = 0,
	RemoveVehicle = 1,
}

local VehicleController = {}
VehicleController.__extends = Component

export type VehicleController = {
	--- Currently driven vehicle
	DrivenVehicle: VehicleTypes.ClientVehicle?,
	--- Player's spawned vehicle
	SpawnedVehicle: VehicleTypes.ClientVehicle?,
	--- All spawned vehicles in the workspace
	WorldVehicles: { VehicleTypes.ClientVehicle },

	--- Fires when a new vehicle spawned via `SpawnVehicle()`
	VehicleSpawned: Signal.Signal<VehicleTypes.ClientVehicle>,

	--- **Yields.** Spawn a new vehicle. Will assert an error if spawned vehicle exists
	SpawnVehicle: (self: VehicleController) -> VehicleTypes.ClientVehicle,
	--- **Yields.** Remove the spawned vehicle. Will assert an error if spawned vehicle not exists
	RemoveVehicle: (self: VehicleController) -> (),
	GetVehicles: (
		self: VehicleController
	) -> { PlayerVehicleType.PlayerVehicle },
	GetVehicleInfo: (
		self: VehicleController,
		id: string
	) -> PlayerVehicleType.PlayerVehicleInfo,
	GetVehiclesByName: (
		self: VehicleController,
		name: string
	) -> { PlayerVehicleType.PlayerVehicle },
} & Component.Component

function VehicleController.new(): VehicleController
	local self: VehicleController = Component(VehicleController) :: any

	self.DrivenVehicle = nil
	self.SpawnedVehicle = nil
	self.WorldVehicles = {}

	self.VehicleSpawned = Signal.new()

	CollectionService:GetInstanceAddedSignal("Vehicle")
		:Connect(
			function(instance: Instance) RegisterVehicle(self, instance) end
		)
	for k, v in CollectionService:GetTagged("Vehicle") do
		RegisterVehicle(self, v)
	end

	return self
end

function RegisterVehicle(self: VehicleController, instance: Instance)
	if not instance:IsDescendantOf(workspace) then return end

	local vehicle = ClientVehicle.new(instance)
	vehicle.DriverChanged:Connect(function(driver)
		if not vehicle.IsDriven then return end

		self.DrivenVehicle = vehicle
		vehicle.DriverChanged:Once(function() self.DrivenVehicle = nil end)
	end)

	if vehicle.IsOwned then
		self.SpawnedVehicle = vehicle
		self.VehicleSpawned:Fire(vehicle)

		-- TODO: Test
		local conn
		conn = vehicle.Instance.AncestryChanged:Connect(function()
			if game:IsDescendantOf(workspace) then return end

			self.SpawnedVehicle = nil
			conn:Disconnect()
		end)
	end
end

function VehicleController.SpawnVehicle(self: VehicleController)
	assert(not self.SpawnedVehicle, "Spawned vehicle already exists")
	RE:FireServer(Actions.SpawnVehicle)

	repeat
		task.wait()
	until self.SpawnedVehicle

	return self.SpawnedVehicle
end

function VehicleController.RemoveVehicle(self: VehicleController)
	assert(self.SpawnedVehicle, "Spawned vehicle not exists")
	RE:FireServer(Actions.RemoveVehicle)

	repeat
		task.wait()
	until self.SpawnedVehicle == nil
end

function VehicleController.GetVehicles(
	self: VehicleController
): { PlayerVehicleType.PlayerVehicle }
	return RF:InvokeServer("GetPlayerVehicles")
end

function VehicleController.GetVehicleInfo(
	self: VehicleController,
	id: string
): PlayerVehicleType.PlayerVehicleInfo
	return RF:InvokeServer("GetPlayerVehicleInfo", id)
end

function VehicleController.GetVehiclesByName(
	self: VehicleController,
	name: string
): { PlayerVehicleType.PlayerVehicle }
	local vehicles = self:GetVehicles()
	local list = {}
	for _, v in vehicles do
		if v.Name == name then table.insert(list, v) end
	end
	return list
end

return VehicleController.new() :: VehicleController
