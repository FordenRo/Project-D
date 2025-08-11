local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GarageDoor = require(ReplicatedStorage.Shared.Classes.GarageDoor)

export type BaseCarService = {
	Instance: Model & {
		GarageDoors: Folder,
		Triggers: Folder,
	},
	Occupants: { Player },
	_RE: RemoteEvent,
	_RF: RemoteFunction,
}

export type CarServiceClient = {
	__index: CarServiceClient,
	_GarageDoors: { GarageDoor.GarageDoor },

	new: (instance: Model) -> CarServiceClient,
} & BaseCarService

export type CarServiceServer = {
	__index: CarServiceServer,

	new: (instance: Model) -> CarServiceServer,
} & BaseCarService

return {}
