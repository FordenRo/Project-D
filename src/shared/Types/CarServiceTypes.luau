export type BaseCarService = {
	Instance: {
		GarageDoors: Folder,
		Triggers: Folder,
	} & Model,
	Occupants: { Player },
}

export type CarServiceClient = BaseCarService

export type CarServiceServer = BaseCarService

return {}
