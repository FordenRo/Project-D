type SteeringType = "Auto" | "Manual"
type FWSteerType = "Static" | "Speed" | "Both" | "None"
type PowerSteeringType = "Old" | "New"

export type Type = {
	--- Steering type
	---
	--- `Auto` - realistically calculates steering angle for you
	---
	--- `Manual` - allows you to manually set the angle of the wheels
	SteeringType: SteeringType,

	--- Steering ratio of your steering rack, google it for your car
	SteerRatio: number,
	--- Number of turns of the steering wheel lock to lock, google it for your car
	LockToLock: number,
	--- If you don't know what it is don't touch it, ranges from .7 to 1.2
	Ackerman: number,

	--- Inner wheel steering (in degrees)
	---
	--- Only when `SteeringType` is `Manual`
	SteerInner: number,
	--- Outer wheel steering (in degrees)
	---
	--- Only when `SteeringType` is `Manual`
	SteerOuter: number,

	--- Steering increment per tick (in degrees)
	SteerSpeed: number,
	--- Steering increment per tick (in degrees)
	ReturnSpeed: number,
	--- Controller version of steer speed (0 or less to be the same as SteerSpeed)
	ContlrSteerSpeed: number,
	--- Controller version of return speed (0 or less to be the same as ReturnSpeed)
	ContlrReturnSpeed: number,
	--- Set to true if you want mouse steering to use controller settings.
	MSteerUsesContlr: boolean,

	--- Speed of gradient cutoff (in km/h)
	SteerDecay: number,
	--- Speed of gradient cutoff of steering speed (in km/h)
	SteerSpeedDecay: number,
	--- Minimum steering angle at max steer decay (in percent)
	MinSteer: number,
	--- Minimum steering speed at max decay (in percent)
	MinSteerSpeed: number,
	--- Mouse steering exponential degree
	MSteerExp: number,

	--- Enables countersteering
	CSEnabled: boolean,
	--- Amount of countersteering at a full perpendicular slide (in percent)
	CSAmt: number,
	--- Threshold before countersteering activates (in percent)
	CSSteerThresh: number,
	--- Speed threshold before countersteering can activate (in km/h)
	CSSpeedThresh: number,

	--- The lower, the smoother the steering will arrive at max angle.
	SteerSmoothing: number,
	--- `New` - uses `AlignOrientation`. Expect a lot of bugs
	---
	--- `Old` - uses `BodyGyro` (Recommended)
	PowerSteeringType: PowerSteeringType,

	--- Steering Damping
	---
	--- Only when `PowerSteeringType` is `Old`
	SteerD: number,
	--- Steering Aggressiveness
	---
	--- Only when `PowerSteeringType` is `Old`
	SteerP: number,
	--- Steering Force
	---
	--- Only when `PowerSteeringType` is `Old`
	SteerMaxTorque: number,

	--- Four wheel steering type
	FWSteer: FWSteerType,
	--- Outer rear wheel steering angle (in degrees)
	RSteerOuter: number,
	--- Inner rear wheel steering angle (in degrees)
	RSteerInner: number,

	--- Speed at which 4WS fully activates (Speed), deactivates (Static), or transition begins (Both) (km/h)
	RSteerSpeed: number,
	--- Speed of gradient cutoff (in km/h)
	RSteerDecay: number,

	--- Rear Steering Damping
	---
	--- Only when `PowerSteeringType` is `Old`
	RSteerD: number,
	--- Rear Steering Aggressiveness
	---
	--- Only when `PowerSteeringType` is `Old`
	RSteerP: number,
	--- Rear Steering Force
	---
	--- Only when `PowerSteeringType` is `Old`
	RSteerMaxTorque: number,
}

return {}
