export type SoundData = {
	Asset: string,
	Emitter: string?,
	PlaybackSpeed: number?,
	Volume: number?,
} & any

export type CachedSoundData = {
	AudioPlayer: AudioPlayer,
	Played: boolean?,
} & SoundData

return {}
