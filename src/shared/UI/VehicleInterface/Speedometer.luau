local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LightController = require(
	ReplicatedStorage.Shared.Classes.ClientVehicle.Controllers.LightController
)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Speedometer = {}
Speedometer.__index = Speedometer

type Speedometer = VehicleTypes.VehicleSpeedometer

type SpeedometerImpl = {
	currentUnit: number,
	units: {
		{
			Unit: string,
			Scaling: number,
			MileageScaling: number,
			MaxSpeed: number,
		}
	},
	trove: Trove.Trove,
	icons: {
		[ImageLabel]: {
			Condition: () -> boolean,
			Color: (Color3 | (boolean) -> Color3)?,
		},
	},
	enabled: boolean,
	glowing: boolean,
} & Speedometer

function Speedometer.new(
	vehicle: VehicleTypes.ClientVehicle,
	instance: Frame
): Speedometer
	local self: SpeedometerImpl = setmetatable({}, Speedometer) :: any

	self.Vehicle = vehicle
	self.Instance = instance
	self.currentUnit = 1
	self.enabled = false
	self.glowing = false
	self.units = {
		{
			Unit = "KM",
			Scaling = (Units.Length_mm / 1000) * 3.6,
			MileageScaling = 1000,
			MaxSpeed = 0,
		},
		{
			Unit = "MI",
			Scaling = (Units.Length_mm / 1000) * 2.23693629,
			MileageScaling = 1609.344,
			MaxSpeed = 0,
		},
	}

	if
		self.Vehicle.Engine.Tune.Superchargers
			+ self.Vehicle.Engine.Tune.Turbochargers
		== 0
	then
		self.Instance.Boost.Visible = false
		self.Instance.BoostBG.Visible = false
		self.Instance.Labels.Boost.Visible = false
	end

	local wDia = 0
	for _, wheel in self.Vehicle.Wheels do
		if wheel.IsDriven and wheel.Instance.Size.Y > wDia then
			wDia = wheel.Instance.Size.Y
		end
	end

	for _, v in self.units do
		v.MaxSpeed = math.ceil(
			v.Scaling
				* (
					self.Vehicle.Tune.SpeedLimit > 0
						and self.Vehicle.Tune.SpeedLimit / ((Units.Length_mm / 1000) * 3.6)
					or wDia
						* math.pi
						* self.Vehicle.Engine.Tune.Redline
						/ 60
						/ (self.Vehicle.Tune.ClutchType == "CVT" and self.Vehicle.Tune.CVTMinRatio or self.Vehicle.Tune.Ratios[#self.Vehicle.Tune.Ratios])
						/ self.Vehicle.Tune.FinalDrive
						/ self.Vehicle.Tune.FDMult
				)
		)
	end

	TachInit(self)
	InitializeIcons(self)

	self.trove = Trove.new()
	self.trove:Connect(RunService.Heartbeat, function() Update(self) end)
	self.trove:Add(task.defer(function()
		while true do
			task.wait(1 / 30)
			SpeedUpdate(self)
		end
	end))
	self.trove:Add(task.defer(function()
		while true do
			task.wait(1)
			MileageUpdate(self)
			FuelUpdate(self)
			TempUpdate(self)
		end
	end))
	self.trove:AttachToInstance(instance)

	return self
end

function Update(self: SpeedometerImpl)
	self.enabled = self.Vehicle.IgnitionState == "On"
		or self.Vehicle.IgnitionState == "Starting"
	self.glowing = self.enabled and not self.Vehicle.Engine.IsOn

	GearUpdate(self)
	TachUpdate(self)
	BoostUpdate(self)
	UpdateIcons(self)
end

function GearUpdate(self: SpeedometerImpl)
	local labels = {
		[-2] = "P",
		[-1] = "R",
		[0] = "N",
	}
	local gearText = labels[self.Vehicle.Gear] or tostring(self.Vehicle.Gear)
	if self.Vehicle.Gear == 1 and self.Vehicle.Tune.ClutchType == "CVT" then
		gearText = "D"
	end
	self.Instance.Gear.Text = gearText
	self.Instance.Gear.TextTransparency = self.Vehicle.Clutch * 0.4
	if self.Vehicle.Gear == -1 then
		self.Instance.Gear.TextColor3 = Color3.new(1, 0.5, 0.5)
	else
		self.Instance.Gear.TextColor3 = Color3.new(1, 1, 1)
	end
end

function SpeedUpdate(self: SpeedometerImpl)
	local speed = 0
	local count = 0
	for _, wheel in self.Vehicle.Wheels do
		if not wheel.IsFront then continue end

		speed += math.abs(
			wheel.Instance.CFrame:VectorToObjectSpace(
				wheel.Instance.AssemblyAngularVelocity
			).X * (wheel.Instance.Size.Y / 2)
		)
		count += 1
	end
	speed = speed / count * self.units[self.currentUnit].Scaling
	self.Instance.Speed.Speed.Text = string.format("%03d", speed):gsub(
		"^0+",
		'<font transparency="0.5">%0</font>'
	)
end

function TachInit(self: SpeedometerImpl)
	local max = math.ceil(self.Vehicle.Engine.Tune.Redline / 1000)
	for i = 0, max do
		local bin = self.Instance.Tach.Bin:Clone()
		bin.Visible = true
		bin.Rotation = i / max * 225 - 135
		bin.Num.Text = tostring(i)
		bin.Num.Rotation = -bin.Rotation
		if i * 1000 > self.Vehicle.Engine.Tune.ShiftRPM then
			bin.Num.TextColor3 = Color3.new(1, 0.2, 0.2)
		end
		bin.Parent = self.Instance.Tach
	end
end

function TachUpdate(self: SpeedometerImpl)
	local function setColor(color: Color3)
		for _, v: ImageLabel in
			{
				self.Instance.Tach.Left.CanvasGroup.FG,
				self.Instance.Tach.Right.CanvasGroup.FG,
			}
		do
			v.ImageColor3 = color
		end
	end

	local max = math.ceil(self.Vehicle.Engine.Tune.Redline / 1000) * 1000
	local rot = self.Vehicle.RPM / max * 225
	self.Instance.Tach.Left.CanvasGroup.FG.Rotation = math.clamp(rot, 0, 180)
	self.Instance.Tach.Right.CanvasGroup.FG.Rotation =
		math.clamp(rot - 180, 0, 45)
	if self.Vehicle.RPM / self.Vehicle.Engine.Tune.ShiftRPM > 0.8 then
		setColor(
			Color3.new(1, 1, 1):Lerp(
				Color3.new(1, 0, 0),
				math.clamp(
					(self.Vehicle.RPM / self.Vehicle.Engine.Tune.ShiftRPM - 0.8)
						/ 0.2,
					0,
					1
				)
			)
		)
	else
		setColor(Color3.new(1, 1, 1))
	end
end

function MileageUpdate(self: SpeedometerImpl)
	local mileage = self.Vehicle.Mileage
		/ self.units[self.currentUnit].MileageScaling
	self.Instance.Mileage.Mileage.Text = string.format("%06.1f", mileage):gsub(
		"^0+",
		'<font transparency="0.5">%0</font>'
	)
end

function BoostUpdate(self: SpeedometerImpl)
	if
		not (
			self.Vehicle.Engine.Tune.Superchargers
			+ self.Vehicle.Engine.Tune.Turbochargers
		)
	then
		return
	end

	local max = self.Vehicle.Engine.Tune.S_Boost
		+ self.Vehicle.Engine.Tune.T_Boost
	local rot = self.Vehicle.Engine.Boost / max * 45
	self.Instance.Boost.Rotation =
		math.clamp(180 - rot / 2, 180 - 45 / 2, 180 + 45 / 2)
	self.Instance.Boost.CanvasGroup.FG.Rotation = math.clamp(rot, 0, 45)
end

function FuelUpdate(self: SpeedometerImpl)
	local function setColor(color: Color3)
		self.Instance.Fuel.CanvasGroup.FG.ImageColor3 = color
		self.Instance.FuelIcon.Icon.ImageColor3 = color
	end

	local rot = self.Vehicle.Fuel / self.Vehicle.Tune.FuelCapacity * 60
	self.Instance.Fuel.CanvasGroup.FG.Rotation = math.clamp(rot, 0, 60)
	if self.Vehicle.Fuel / self.Vehicle.Tune.FuelCapacity < 0.3 then
		setColor(
			Color3.new(1, 1, 1):Lerp(
				Color3.new(1, 0, 0),
				math.clamp(
					1
						- (
								self.Vehicle.Fuel
								/ self.Vehicle.Tune.FuelCapacity
							)
							/ 0.3,
					0,
					1
				)
			)
		)
	else
		setColor(Color3.new(1, 1, 1))
	end
end

function TempUpdate(self: SpeedometerImpl)
	local function setColor(color: Color3)
		self.Instance.Temp.CanvasGroup.FG.ImageColor3 = color
		self.Instance.TempIcon.Icon.ImageColor3 = color
	end

	local rot = (self.Vehicle.Engine.Temperature - 60)
		/ (self.Vehicle.Engine.Tune.EngineBurnTemp - 65)
		* 60
	self.Instance.Temp.CanvasGroup.FG.Rotation = 180 - math.clamp(rot, 0, 60)

	if
		self.Vehicle.Engine.Temperature
			/ (self.Vehicle.Engine.Tune.EngineBurnTemp - 5)
		< 0.3
	then
		setColor(
			Color3.new(1, 1, 1):Lerp(
				Color3.new(1, 0, 0),
				math.clamp(
					1
						- (
								self.Vehicle.Engine.Temperature
								/ (self.Vehicle.Engine.Tune.EngineBurnTemp - 5)
							)
							/ 0.3,
					0,
					1
				)
			)
		)
	else
		setColor(Color3.new(1, 1, 1))
	end
end

function InitializeIcons(self: SpeedometerImpl)
	local lightController =
		self.Vehicle:GetController("LightController") :: LightController.LightController

	self.icons = {
		[self.Instance.PBrake] = {
			Condition = function() return self.Vehicle.PBrake end,
			Color = Color3.new(1, 0, 0),
		},
		[self.Instance.Battery] = {
			Condition = function() return not self.Vehicle.Engine.IsOn end,
			Color = Color3.new(1, 0, 0),
		},
		[self.Instance.Check] = {
			Condition = function()
				return (self.Vehicle.Engine.Health :: number) < 0.3
			end,
			Color = function(state)
				return state
						and (self.Vehicle.Engine.Health == 0 and Color3.new(
							1,
							0,
							0
						) or Color3.new(1, 0.5, 0))
					or Color3.new()
			end,
		},
		[self.Instance.LowBeam] = {
			Condition = function() return lightController.State == "Low" end,
			Color = Color3.new(0, 1, 0),
		},
		[self.Instance.HighBeam] = {
			Condition = function() return lightController.State == "High" end,
		},
		[self.Instance.RTurn] = {
			Condition = function()
				return (
					lightController.TurnState == "Right"
					or lightController.TurnState == "Both"
				) and math.round(tick() * 2) % 2 == 0
			end,
			Color = Color3.new(0.2, 1, 0.2),
		},
		[self.Instance.LTurn] = {
			Condition = function()
				return (
					lightController.TurnState == "Left"
					or lightController.TurnState == "Both"
				) and math.round(tick() * 2) % 2 == 0
			end,
			Color = Color3.new(0.2, 1, 0.2),
		},
		[self.Instance.ABS] = {
			Condition = function()
				return not self.Vehicle.ABS or self.Vehicle.ABSActive
			end,
			Color = function(state)
				return state
						and ((not self.Vehicle.ABS or self.glowing) and Color3.new(
							1,
							0,
							0
						) or Color3.new(1, 1, 1))
					or Color3.new()
			end,
		},
		[self.Instance.TCS] = {
			Condition = function()
				return not self.Vehicle.TCS or self.Vehicle.TCSActive
			end,
			Color = function(state)
				return state
						and ((not self.Vehicle.TCS or self.glowing) and Color3.new(
							1,
							0,
							0
						) or Color3.new(1, 1, 1))
					or Color3.new()
			end,
		},
	}
end

function UpdateIcons(self: SpeedometerImpl)
	for instance, config in self.icons do
		local condition = (config.Condition() or self.glowing) and self.enabled
		instance.ImageTransparency = condition and 0.2 or 0.8

		if typeof(config.Color) == "function" then
			instance.ImageColor3 = config.Color(condition)
		elseif typeof(config.Color) == "Color3" then
			instance.ImageColor3 = condition and config.Color or Color3.new()
		end
	end
end

return table.freeze({ new = Speedometer.new })
