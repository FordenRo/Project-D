type SoundDataType = "Engine" | "Transmission" | "Turbo" | "Super" | "Blowoff" | "Ignition" | "Fan"

export type SoundData = {
	SoundId: string,
	Type: SoundDataType,
	Parent: string?,
	BasePlaybackSpeed: number,
	BaseVolume: number,
	RangeEnd: number,
	RangeStart: number,
	RedlinePlaybackSpeed: number,
	RedlineVolume: number,
	ThrottleVolume: number,
	TransitionEnd: number,
	TransitionStart: number,
	ClutchVolume: number,
	Gears: { number },
	OffVolume: number,
	VariablePlaybackSpeed: number,
	VariableVolume: number,
	PlaybackSpeedIncrease: number,
	VolumeIncrease: number,
	Sensitivity: number,
	MaxPitch: number,
	Pitch: number,
	Volume: number,
}

return {}
