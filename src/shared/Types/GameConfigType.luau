export type GameConfig = {
	--- The current version of the game
	Version: string,
	--- Versions changelog
	Changelog: { [string]: string },
	--- Welcome message displayed to player
	Welcome: string,
}

return {}
