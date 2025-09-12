local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local Aerodynamics = {}
Aerodynamics.__index = Aerodynamics

export type Aerodynamics = {
	__index: Aerodynamics,
	_DragFactor: number,
	_Forces: {
		Drag: VectorForce,
		FDownforce: VectorForce,
		RDownforce: VectorForce,
	},
	Vehicle: VehicleTypes.ClientVehicle,

	new: (vehicle: VehicleTypes.ClientVehicle) -> Aerodynamics,
}

function Aerodynamics.new(vehicle: VehicleTypes.ClientVehicle): Aerodynamics
	local self: Aerodynamics = setmetatable({}, Aerodynamics) :: any

	self.Vehicle = vehicle

	Initialize(self)

	local trove = Trove.new()
	trove:Add(task.spawn(function()
		while true do
			task.wait(1 / 30)
			Update(self)
		end
	end))
	trove:Add(function()
		for _, v in self._Forces do
			v.Attachment0:Destroy()
			v:Destroy()
		end
	end)
	self.Vehicle.DrivenChanged:Once(function() trove:Destroy() end)

	return self
end

function Initialize(self: Aerodynamics)
	-- Attachments
	local dragAttach = Instance.new("Attachment")
	dragAttach.Parent = self.Vehicle.Instance.Body.Aerodynamics.Drag

	local fDownforceAttach = Instance.new("Attachment")
	fDownforceAttach.Parent = self.Vehicle.Instance.Body.Aerodynamics.FDownforce

	local rDownforceAttach = Instance.new("Attachment")
	rDownforceAttach.Parent = self.Vehicle.Instance.Body.Aerodynamics.RDownforce

	-- Forces
	local dragForce = Instance.new("VectorForce")
	dragForce.Attachment0 = dragAttach
	dragForce.Force = Vector3.zero
	dragForce.RelativeTo = Enum.ActuatorRelativeTo.World
	dragForce.Parent = self.Vehicle.Instance.Body.Aerodynamics.Drag

	local fDownforce = Instance.new("VectorForce")
	fDownforce.Attachment0 = fDownforceAttach
	fDownforce.Force = Vector3.zero
	fDownforce.RelativeTo = Enum.ActuatorRelativeTo.World
	fDownforce.Parent = self.Vehicle.Instance.Body.Aerodynamics.FDownforce

	local rDownforce = Instance.new("VectorForce")
	rDownforce.Attachment0 = rDownforceAttach
	rDownforce.Force = Vector3.zero
	rDownforce.RelativeTo = Enum.ActuatorRelativeTo.World
	rDownforce.Parent = self.Vehicle.Instance.Body.Aerodynamics.RDownforce

	self._Forces = {
		Drag = dragForce,
		FDownforce = fDownforce,
		RDownforce = rDownforce,
	}
end

function Update(self: Aerodynamics)
	if (self.Vehicle.WeightPart.AssemblyLinearVelocity - game.Workspace.GlobalWind).Magnitude < 1 then return end

	local AirPressurePercent = math.exp(
		(-9.80665 * 0.0289644 * (self.Vehicle.Center.Position.Y * Units.Length_mm / 1000))
			/ (8.3142 * ((game.Workspace:GetAttribute("GlobalTemperature") :: number) + 273.15))
	) * (game.Workspace.AirDensity / 0.001)

	-- Slipstream
	local dragFactor = 1

	local toRayParams = RaycastParams.new()
	toRayParams.FilterType = Enum.RaycastFilterType.Exclude
	toRayParams.FilterDescendantsInstances = { self.Vehicle.Instance, player.Character }

	local toRay = game.Workspace:Raycast(
		self.Vehicle.WeightPart.Position,
		self.Vehicle.WeightPart.CFrame.LookVector * 1000,
		toRayParams
	)
	if toRay then
		local fromRayParams = RaycastParams.new()
		fromRayParams.FilterType = Enum.RaycastFilterType.Exclude
		fromRayParams.FilterDescendantsInstances = (toRay.Instance :: BasePart):GetConnectedParts()

		local fromRay = game.Workspace:Raycast(
			toRay.Position,
			-toRay.Instance.Velocity * self.Vehicle.Tune.AeroSlipstreamTime,
			fromRayParams
		)
		if fromRay and fromRay.Instance:IsDescendantOf(self.Vehicle.Instance) then
			dragFactor = (1 - self.Vehicle.Tune.AeroSlipstreamFactor)
				+ (
					fromRay.Distance
					/ (toRay.Instance.Velocity * self.Vehicle.Tune.AeroSlipstreamTime).Magnitude
					* self.Vehicle.Tune.AeroSlipstreamFactor
				)
		end
	end

	-- Apply forces
	local carVel = self.Vehicle.WeightPart.AssemblyLinearVelocity * (Units.Length_mm / 1000) * 3.6
	local windVel = game.Workspace.GlobalWind * (Units.Length_mm / 1000) * 3.6
	local diff = carVel - windVel
	local objectVel = self.Vehicle.WeightPart.CFrame:VectorToObjectSpace(carVel - windVel)

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

	self._Forces.FDownforce.Force = self.Vehicle.WeightPart.CFrame.UpVector * fDownforce * 9.81 * Units.Force_N
	self._Forces.RDownforce.Force = self.Vehicle.WeightPart.CFrame.UpVector * rDownforce * 9.81 * Units.Force_N
	self._Forces.Drag.Force = combinedForce * 9.81 * Units.Force_N

	-- Apply sounds
	local wind = self.Vehicle.SoundController.Sounds.Wind.AudioPlayer :: AudioPlayer
	local body = self.Vehicle.SoundController.Sounds.Body.AudioPlayer :: AudioPlayer
	if not wind.IsPlaying or not body.IsPlaying then
		wind:Play()
		body:Play()
	end
	wind.Volume = diff.Magnitude ^ 2 * self.Vehicle.Tune.AeroWindVolume / 200 ^ 2
	body.Volume = diff.Magnitude ^ 2 * self.Vehicle.Tune.AeroBodyVolume / 200 ^ 2
end

return Aerodynamics
