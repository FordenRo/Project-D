export type SoundData = {
	Asset: string,
	Emitter: string?,
	PlaybackSpeed: number?,
	Volume: number?,
} & any

export type CachedSoundData = SoundData & {
	AudioPlayer: AudioPlayer,
	Played: boolean?,
}

return {}
