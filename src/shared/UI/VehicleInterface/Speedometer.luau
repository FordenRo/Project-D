local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local Speedometer = {}
Speedometer.__index = Speedometer

type Speedometer = VehicleTypes.VehicleSpeedometer

function Speedometer.new(vehicle: VehicleTypes.ClientVehicle, instance: Frame)
	local self: Speedometer = setmetatable({}, Speedometer) :: any

	self.Vehicle = vehicle
	self.Instance = instance
	self.CurrentUnit = 1
	self.Units = {
		{
			Unit = "KM",
			Scaling = (Units.Length_mm / 1000) * 3.6,
			MaxSpeed = 0,
		},
		{
			Unit = "MI",
			Scaling = (Units.Length_mm / 1000) * 2.23693629,
			MaxSpeed = 0,
		},
	}

	if self.Vehicle.Tune.Superchargers + self.Vehicle.Tune.Turbochargers == 0 then
		self.Instance.Boost.Visible = false
		self.Instance.BoostBG.Visible = false
		self.Instance.Labels.Boost.Visible = false
	end

	local wDia = 0
	for _, wheel in self.Vehicle.Wheels do
		if wheel.IsDriven and wheel.Instance.Size.Y > wDia then wDia = wheel.Instance.Size.Y end
	end

	for _, v in pairs(self.Units) do
		v.MaxSpeed = math.ceil(
			v.Scaling
				* (
					self.Vehicle.Tune.SpeedLimit > 0
						and self.Vehicle.Tune.SpeedLimit / ((Units.Length_mm / 1000) * 3.6)
					or wDia
						* math.pi
						* self.Vehicle.Tune.Redline
						/ 60
						/ (self.Vehicle.Tune.ClutchType == "CVT" and self.Vehicle.Tune.CVTMinRatio or self.Vehicle.Tune.Ratios[#self.Vehicle.Tune.Ratios])
						/ self.Vehicle.Tune.FinalDrive
						/ self.Vehicle.Tune.FDMult
				)
		)
	end

	TachInit(self)

	self._conn = RunService.Heartbeat:Connect(function() Update(self) end)
	self._task = task.spawn(function()
		while true do
			task.wait(1 / 10)
			SlowUpdate(self)
		end
	end)

	return self
end

function Update(self: Speedometer)
	SpeedUpdate(self)
	TachUpdate(self)
	ABSUpdate(self)
	BoostUpdate(self)
	TSCUpdate(self)
end

function SlowUpdate(self: Speedometer)
	GearUpdate(self)
	MileageUpdate(self)
	FuelUpdate(self)
	TempUpdate(self)
	UpdateIcons(self)
end

function GearUpdate(self: Speedometer)
	local labels = {
		[-2] = "P",
		[-1] = "R",
		[0] = "N",
	}
	local gearText = labels[self.Vehicle.Gear] or tostring(self.Vehicle.Gear)
	if self.Vehicle.Gear == 1 and self.Vehicle.Tune.ClutchType == "CVT" then gearText = "D" end
	self.Instance.Gear.Text = gearText
	self.Instance.Gear.TextTransparency = self.Vehicle.Clutch * 0.4
	if self.Vehicle.Gear == -1 then
		self.Instance.Gear.TextColor3 = Color3.new(1, 0.5, 0.5)
	else
		self.Instance.Gear.TextColor3 = Color3.new(1, 1, 1)
	end
end

function SpeedUpdate(self: Speedometer)
	local speed = self.Vehicle.Velocity.Magnitude * self.Units[self.CurrentUnit].Scaling
	self.Instance.Speed.Speed.Text = string.format("%03d", speed):gsub("^0+", '<font transparency="0.5">%0</font>')
end

function TachInit(self: Speedometer)
	local max = math.ceil(self.Vehicle.Tune.Redline / 1000)
	for i = 0, max do
		local bin = self.Instance.Tach.Bin:Clone()
		bin.Visible = true
		bin.Rotation = i / max * 225 - 135
		bin.Num.Text = tostring(i)
		bin.Num.Rotation = -bin.Rotation
		if i * 1000 > self.Vehicle.Tune.ShiftRPM then bin.Num.TextColor3 = Color3.new(1, 0.2, 0.2) end
		bin.Parent = self.Instance.Tach
	end
end

function TachUpdate(self: Speedometer)
	local function setColor(color: Color3)
		for _, v: ImageLabel in { self.Instance.Tach.Left.CanvasGroup.FG, self.Instance.Tach.Right.CanvasGroup.FG } do
			v.ImageColor3 = color
		end
	end

	local max = math.ceil(self.Vehicle.Tune.Redline / 1000) * 1000
	local rot = self.Vehicle.RPM / max * 225
	self.Instance.Tach.Left.CanvasGroup.FG.Rotation = math.clamp(rot, 0, 180)
	self.Instance.Tach.Right.CanvasGroup.FG.Rotation = math.clamp(rot - 180, 0, 45)
	if self.Vehicle.RPM / self.Vehicle.Tune.ShiftRPM > 0.8 then
		setColor(
			Color3.new(1, 1, 1)
				:Lerp(
					Color3.new(1, 0, 0),
					math.clamp((self.Vehicle.RPM / self.Vehicle.Tune.ShiftRPM - 0.8) / 0.2, 0, 1)
				)
		)
	else
		setColor(Color3.new(1, 1, 1))
	end
end

function MileageUpdate(self: Speedometer)
	local mileage = self.Vehicle.Mileage * self.Units[self.CurrentUnit].Scaling
	self.Instance.Mileage.Mileage.Text =
		string.format("%06.1f", mileage):gsub("^0+", '<font transparency="0.5">%0</font>')
end

function BoostUpdate(self: Speedometer)
	if not (self.Vehicle.Tune.Superchargers + self.Vehicle.Tune.Turbochargers) then return end

	local max = self.Vehicle.Tune.S_Boost + self.Vehicle.Tune.T_Boost
	local rot = self.Vehicle.Boost / max * 45
	self.Instance.Boost.Rotation = math.clamp(180 - rot / 2, 180 - 45 / 2, 180 + 45 / 2)
	self.Instance.Boost.CanvasGroup.FG.Rotation = math.clamp(rot, 0, 45)
end

function FuelUpdate(self: Speedometer)
	local function setColor(color: Color3)
		self.Instance.Fuel.CanvasGroup.FG.ImageColor3 = color
		self.Instance.FuelIcon.Icon.ImageColor3 = color
	end

	local rot = self.Vehicle.Fuel / self.Vehicle.Tune.FuelCapacity * 60
	self.Instance.Fuel.CanvasGroup.FG.Rotation = math.clamp(rot, 0, 60)
	if self.Vehicle.Fuel / self.Vehicle.Tune.FuelCapacity < 0.3 then
		setColor(
			Color3.new(1, 1, 1)
				:Lerp(
					Color3.new(1, 0, 0),
					math.clamp(1 - (self.Vehicle.Fuel / self.Vehicle.Tune.FuelCapacity) / 0.3, 0, 1)
				)
		)
	else
		setColor(Color3.new(1, 1, 1))
	end
end

function TempUpdate(self: Speedometer)
	local function setColor(color: Color3)
		self.Instance.Temp.CanvasGroup.FG.ImageColor3 = color
		self.Instance.TempIcon.Icon.ImageColor3 = color
	end

	local rot = (self.Vehicle.Temperature - 60) / (self.Vehicle.Tune.EngineBurnTemp - 65) * 60
	self.Instance.Temp.CanvasGroup.FG.Rotation = 180 - math.clamp(rot, 0, 60)

	if self.Vehicle.Temperature / (self.Vehicle.Tune.EngineBurnTemp - 5) < 0.3 then
		setColor(
			Color3.new(1, 1, 1):Lerp(
				Color3.new(1, 0, 0),
				math.clamp(1 - (self.Vehicle.Temperature / (self.Vehicle.Tune.EngineBurnTemp - 5)) / 0.3, 0, 1)
			)
		)
	else
		setColor(Color3.new(1, 1, 1))
	end
end

function UpdateIcons(self: Speedometer)
	-- PBrake
	self.Instance.PBrake.ImageColor3 = (self.Vehicle.PBrake or self.Vehicle.Starting) and Color3.new(1, 1, 1)
		or Color3.new()
	self.Instance.PBrake.ImageTransparency = (self.Vehicle.PBrake or self.Vehicle.Starting) and 0.2 or 0.8

	-- Battery
	self.Instance.Battery.ImageColor3 = (not self.Vehicle.IsOn or self.Vehicle.Starting) and Color3.new(1, 0, 0)
		or Color3.new()
	self.Instance.Battery.ImageTransparency = (not self.Vehicle.IsOn or self.Vehicle.Starting) and 0.2 or 0.8

	-- Check
	self.Instance.Check.ImageColor3 = (self.Vehicle.Starting or self.Vehicle.Broken) and Color3.new(1, 0, 0)
		or self.Vehicle.EngineHealth < 0.2 and Color3.new(1, 0.5, 0)
		or Color3.new()
	self.Instance.Check.ImageTransparency = (
		self.Vehicle.Starting
		or self.Vehicle.Broken
		or self.Vehicle.EngineHealth < 0.2
	)
			and 0.2
		or 0.8

	-- Lights
	-- Low beam
	self.Instance.LowBeam.ImageColor3 = self.Vehicle.Starting and Color3.new(1, 0, 0) or Color3.new()
	self.Instance.LowBeam.ImageTransparency = self.Vehicle.Starting and 0.2 or 0.8
	self.Instance.LowBeam.Visible = true
	-- High beam
	self.Instance.HighBeam.Visible = false

	-- Turn signals
	-- Right
	self.Instance.RTurn.ImageColor3 = self.Vehicle.Starting and Color3.new(0.2, 1, 0.2) or Color3.new()
	self.Instance.RTurn.ImageTransparency = self.Vehicle.Starting and 0.2 or 0.8

	-- Left
	self.Instance.LTurn.ImageColor3 = self.Vehicle.Starting and Color3.new(0.2, 1, 0.2) or Color3.new()
	self.Instance.LTurn.ImageTransparency = self.Vehicle.Starting and 0.2 or 0.8
end

function ABSUpdate(self: Speedometer)
	if self.Vehicle.Starting or not self.Vehicle.ABS then
		self.Instance.ABS.ImageColor3 = Color3.new(1, 0, 0)
		self.Instance.ABS.ImageTransparency = 0.2
	else
		if self.Vehicle.ABSActive then
			self.Instance.ABS.ImageColor3 = Color3.new(1, 1, 1)
			self.Instance.ABS.ImageTransparency = 0.2
		else
			self.Instance.ABS.ImageColor3 = Color3.new()
			self.Instance.ABS.ImageTransparency = 0.8
		end
	end
end

function TSCUpdate(self: Speedometer)
	if self.Vehicle.Starting or not self.Vehicle.TCS then
		self.Instance.TCS.ImageColor3 = Color3.new(1, 0, 0)
		self.Instance.TCS.ImageTransparency = 0.2
	else
		if self.Vehicle.TCSActive then
			self.Instance.TCS.ImageColor3 = Color3.new(1, 1, 1)
			self.Instance.TCS.ImageTransparency = 0.2
		else
			self.Instance.TCS.ImageColor3 = Color3.new()
			self.Instance.TCS.ImageTransparency = 0.8
		end
	end
end

function Speedometer.Destroy(self: Speedometer)
	self.Instance:Destroy()
	self._conn:Disconnect()
	task.cancel(self._task)
end

return Speedometer
