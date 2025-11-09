export type GameConfig = {
	--- The current version of the game
	Version: string,
	--- Version's changelog
	Changelog: { Update },
	--- Project's roadmap
	Roadmap: { Update },
	--- Welcome message displayed to player
	Welcome: string,
}

export type UpdateType = "Patch" | "Bugfix" | "Update"

export type Update = {
	Type: UpdateType,
	Version: string,
	Title: string?,
	Description: string,
}

return {}
