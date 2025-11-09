local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local Aerodynamics = {}
Aerodynamics.__index = Aerodynamics

export type Aerodynamics = {
	Vehicle: VehicleTypes.ClientVehicle,
}

type AerodynamicsImpl = {
	trove: Trove.Trove,
	dragFactor: number,
	forces: {
		drag: VectorForce,
		fDownforce: VectorForce,
		rDownforce: VectorForce,
	},
} & Aerodynamics

function Aerodynamics.new(vehicle: VehicleTypes.ClientVehicle): Aerodynamics
	local self: AerodynamicsImpl = setmetatable({}, Aerodynamics) :: any

	self.Vehicle = vehicle
	self.trove = Trove.new()

	self.Vehicle.DriverChanged:Connect(function()
		if self.Vehicle.IsDriven then
			Initialize(self)
		elseif not self.trove:IsEmpty() then
			self.trove:Destroy()
		end
	end)

	return self
end

function Initialize(self: AerodynamicsImpl)
	-- Attachments
	local dragAttach = Instance.new("Attachment")
	dragAttach.Parent = self.Vehicle.Instance.Body.Aerodynamics.Drag
	self.trove:Add(dragAttach)

	local fDownforceAttach = Instance.new("Attachment")
	fDownforceAttach.Parent = self.Vehicle.Instance.Body.Aerodynamics.FDownforce
	self.trove:Add(fDownforceAttach)

	local rDownforceAttach = Instance.new("Attachment")
	rDownforceAttach.Parent = self.Vehicle.Instance.Body.Aerodynamics.RDownforce
	self.trove:Add(rDownforceAttach)

	-- Forces
	local dragForce = Instance.new("VectorForce")
	dragForce.Attachment0 = dragAttach
	dragForce.Force = Vector3.zero
	dragForce.RelativeTo = Enum.ActuatorRelativeTo.World
	dragForce.Parent = self.Vehicle.Instance.Body.Aerodynamics.Drag
	self.trove:Add(dragForce)

	local fDownforce = Instance.new("VectorForce")
	fDownforce.Attachment0 = fDownforceAttach
	fDownforce.Force = Vector3.zero
	fDownforce.RelativeTo = Enum.ActuatorRelativeTo.World
	fDownforce.Parent = self.Vehicle.Instance.Body.Aerodynamics.FDownforce
	self.trove:Add(fDownforce)

	local rDownforce = Instance.new("VectorForce")
	rDownforce.Attachment0 = rDownforceAttach
	rDownforce.Force = Vector3.zero
	rDownforce.RelativeTo = Enum.ActuatorRelativeTo.World
	rDownforce.Parent = self.Vehicle.Instance.Body.Aerodynamics.RDownforce
	self.trove:Add(rDownforce)

	self.forces = {
		drag = dragForce,
		fDownforce = fDownforce,
		rDownforce = rDownforce,
	}

	self.trove:Add(task.spawn(function()
		while true do
			task.wait(1 / 30)
			Update(self)
		end
	end))
end

function Update(self: AerodynamicsImpl)
	if (self.Vehicle.Velocity - workspace.GlobalWind).Magnitude < 1 then
		return
	end

	local AirPressurePercent = math.exp(
		(
			-9.80665
			* 0.0289644
			* (self.Vehicle.Center.Position.Y * Units.Length_mm / 1000)
		)
			/ (
				8.3142
				* (
					(workspace:GetAttribute("GlobalTemperature") :: number)
					+ 273.15
				)
			)
	) * (workspace.AirDensity / 0.001)

	-- Slipstream
	local dragFactor = 1

	local toRayParams = RaycastParams.new()
	toRayParams.FilterType = Enum.RaycastFilterType.Exclude
	toRayParams.FilterDescendantsInstances =
		{ self.Vehicle.Instance, player.Character :: Model }

	local toRay = workspace:Raycast(
		self.Vehicle.CFrame.Position,
		self.Vehicle.CFrame.LookVector * 1000,
		toRayParams
	)
	if toRay then
		local fromRayParams = RaycastParams.new()
		fromRayParams.FilterType = Enum.RaycastFilterType.Exclude
		fromRayParams.FilterDescendantsInstances = (
				toRay.Instance :: BasePart
			):GetConnectedParts() :: any

		local fromRay = workspace:Raycast(
			toRay.Position,
			-(toRay.Instance :: BasePart).AssemblyLinearVelocity
				* self.Vehicle.Tune.AeroSlipstreamTime,
			fromRayParams
		)
		if
			fromRay and fromRay.Instance:IsDescendantOf(self.Vehicle.Instance)
		then
			dragFactor = (1 - self.Vehicle.Tune.AeroSlipstreamFactor)
				+ (
					fromRay.Distance
					/ (
						(toRay.Instance :: BasePart).AssemblyLinearVelocity
						* self.Vehicle.Tune.AeroSlipstreamTime
					).Magnitude
					* self.Vehicle.Tune.AeroSlipstreamFactor
				)
		end
	end

	-- Apply forces
	local carVel = self.Vehicle.Velocity * (Units.Length_mm / 1000) * 3.6
	local windVel = workspace.GlobalWind * (Units.Length_mm / 1000) * 3.6
	local diff = carVel - windVel
	local objectVel = self.Vehicle.CFrame:VectorToObjectSpace(carVel - windVel)

	local fDownforce = math.sign(objectVel.Z)
		* (objectVel.Z ^ 2 / 200 ^ 2)
		* self.Vehicle.Tune.AeroFDownforce
		* dragFactor
	local rDownforce = math.sign(objectVel.Z)
		* (objectVel.Z ^ 2 / 200 ^ 2)
		* self.Vehicle.Tune.AeroRDownforce
		* dragFactor
	local combinedForce = -diff.Unit
		* diff.Magnitude ^ 2
		* ((self.Vehicle.Tune.AeroDragCoeff * 1.5) / 100)
		* AirPressurePercent

	self.forces.fDownforce.Force = self.Vehicle.CFrame.UpVector
		* fDownforce
		* 9.81
		* Units.Force_N
	self.forces.rDownforce.Force = self.Vehicle.CFrame.UpVector
		* rDownforce
		* 9.81
		* Units.Force_N
	self.forces.drag.Force = combinedForce * 9.81 * Units.Force_N

	-- Apply sounds
	local wind =
		self.Vehicle.SoundController.Sounds.Wind.AudioPlayer :: AudioPlayer
	local body =
		self.Vehicle.SoundController.Sounds.Body.AudioPlayer :: AudioPlayer
	if not wind.IsPlaying or not body.IsPlaying then
		wind:Play()
		body:Play()
	end
	wind.Volume = diff.Magnitude ^ 2
		* self.Vehicle.Tune.AeroWindVolume
		/ 200 ^ 2
	body.Volume = diff.Magnitude ^ 2
		* self.Vehicle.Tune.AeroBodyVolume
		/ 200 ^ 2
end

function Aerodynamics.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == Aerodynamics
end

return table.freeze({
	new = Aerodynamics.new,
	Is = Aerodynamics.Is,
})
