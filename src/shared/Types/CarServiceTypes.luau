export type BaseCarService = {
	Instance: Model & {
		GarageDoors: Folder,
		Triggers: Folder,
	},
	Occupants: { Player },
}

export type CarServiceClient = BaseCarService

export type CarServiceServer = BaseCarService

return {}
