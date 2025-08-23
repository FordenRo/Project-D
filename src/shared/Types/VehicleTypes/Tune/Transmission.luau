export type TransmissionMode = "Auto" | "Semi" | "Manual"
type ClutchMode = "New" | "Old"
type ClutchType = "Clutch" | "TorqueConverter" | "CVT"
type AutoShiftMode = "Speed" | "RPM"
type AutoShiftType = "Rev" | "DCT"
type AutoShiftVers = "New" | "Old"

export type Type = {
	--- Implements a realistic clutch, change to "false" for the chassis to act like AC6.81T.
	Clutch: boolean,
	--[[
        `Auto` - Automatic shifting

        `Semi` - Clutchless manual shifting, dual clutch transmission

        `Manual` - Manual shifting with clutch

        First mode is default mode
    ]]
	TransModes: { TransmissionMode },
	--[[
        `New` - Speed controls clutch engagement

        `Old` - Speed and RPM controls clutch engagement
    ]]
	ClutchMode: ClutchMode,
	--[[
        `Clutch` - Standart clutch, recommended

        `TorqueConverter` - Torque converter, keeps RPM up

        `CVT` - Continously Variable Transmission
    ]]
	ClutchType: ClutchType,

	--- Stalling, enables the car to stall. An ignition plugin would be necessary. Disables if Tune.Clutch is false.
	Stall: boolean,
	--- If true, the driver must let off the gas before shifting to a higher gear. Recommended false for beginners.
	ClutchRel: boolean,
	--- How fast engagement is (0 = instant, 99 = super slow)
	ClutchEngage: number,
	--- Speed the clutch fully engages at (Based on km/h)
	SpeedEngage: number,
	--- Clutch RPM multiplier, recommended to leave at `1.0`
	---
	--- Only when `ClutchMode` is `Old`
	ClutchRPMMult: number,

	--- Torque converter starts locking at a certain RPM
	TQLock: boolean,
	--- Keeps RPMs to this level until passed
	RPMEngage: number,

	--- RPM that the CVT wants to keep at full throttle.
	CVTRPM: number,
	--- The gear ratio that the CVT cannot go over.
	CVTMaxRatio: number,
	--- The gear ratio that the CVT cannot go under.
	CVTMinRatio: number,

	--- Enables a different redline RPM for when the car is in neutral
	NeutralLimit: boolean,
	--- The rev limiter when the car is in neutral
	NeutralRevRPM: number,
	--- Will also limit RPMs while the clutch is pressed down
	LimitClutch: boolean,

	--- `Speed` - Shifts based on wheel speed
	---
	--- `RPM` - Shifts based on RPM
	AutoShiftMode: AutoShiftMode,
	--- `Rev` - Clutch engages fully once RPM reached
	---
	--- `DCT` - Clutch engages after a set time has passed
	AutoShiftType: AutoShiftType,
	--- `New` - Shift from Reverse, Neutral and Drive
	---
	--- `Old` - Auto shifts into R or D when stopped
	AutoShiftVers: AutoShiftVers,
	--- Automatic upshift point 	(relative to peak RPM, positive = Over-rev)
	AutoUpThresh: number,
	--- Automatic downshift point (relative to peak RPM, positive = Under-rev)
	AutoDownThresh: number,

	--- (Automatic) Throttle level when shifting down to revmatch, 0 - 100%
	ShiftThrot: number,
	--- (Automatic) (DCT) Time required to shift into next gear, from a lower gear to a higher one.
	ShiftUpTime: number,
	--- (Automatic) (DCT) Time required to shift into next gear, from a higher gear to a lower one.
	ShiftDnTime: number,

	--- Final drive ratio
	FinalDrive: number,
	--[[
        { `Park*`, `Reverse`, `Neutral`, `1`, `2` ... }

        `Park` - If set to 0, enabled parking gear, otherwise it will count as `Reverse`
    ]]
	Ratios: { number },
	--- Ratio multiplier (keep this at 1 if car is not struggling with torque)
	FDMult: number,
}

return {}
