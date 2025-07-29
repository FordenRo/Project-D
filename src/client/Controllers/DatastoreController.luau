local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DatastoreController = {}
DatastoreController.__index = DatastoreController

export type DatastoreController = typeof(setmetatable({} :: {}, DatastoreController))

local remote: RemoteFunction = ReplicatedStorage.Remotes:WaitForChild("DatastoreRemote")

function DatastoreController.new()
	local self: DatastoreController = setmetatable({}, DatastoreController) :: any

	return self
end

function DatastoreController.GetControls(self: DatastoreController) return remote:InvokeServer("Controls") end

return DatastoreController.new()
