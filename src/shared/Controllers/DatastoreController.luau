local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local DatastoreController = {}
DatastoreController.__index = DatastoreController

export type DatastoreController = typeof(setmetatable({} :: {}, DatastoreController))

local remoteFunction: RemoteFunction = ReplicatedStorage:WaitForChild("DatastoreRF")
local remoteEvent: RemoteEvent = ReplicatedStorage:WaitForChild("DatastoreRE")

function DatastoreController.new()
	local self: DatastoreController = setmetatable({}, DatastoreController) :: any

	return self
end

function DatastoreController.GetControls(self: DatastoreController) return remoteFunction:InvokeServer("Controls") end

function DatastoreController.SetControls(self: DatastoreController, controls: VehicleTypes.VehicleControls)
	remoteEvent:FireServer("Controls", controls)
end

return DatastoreController.new()
