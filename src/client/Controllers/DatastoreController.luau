local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Vehicle.Types)

local DatastoreController = {}
DatastoreController.__index = DatastoreController

export type DatastoreController = typeof(setmetatable({} :: {}, DatastoreController))

local remoteFunction: RemoteFunction = ReplicatedStorage.Remotes:WaitForChild("DatastoreRF")
local remoteEvent: RemoteEvent = ReplicatedStorage.Remotes:WaitForChild("DatastoreRE")

function DatastoreController.new()
	local self: DatastoreController = setmetatable({}, DatastoreController) :: any

	return self
end

function DatastoreController.GetControls(self: DatastoreController) return remoteFunction:InvokeServer("Controls") end

function DatastoreController.SetControls(self: DatastoreController, controls: Types.VehicleControls)
	remoteEvent:FireServer("Controls", controls)
end

return DatastoreController.new()
