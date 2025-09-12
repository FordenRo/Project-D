local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local SettingsController = require(ReplicatedStorage.Shared.Controllers.SettingsController)
local SpeedEffect = require(script.SpeedEffect)
local Speedometer = require(script.Speedometer)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local UI = ReplicatedStorage.UI.VehicleInterface
local player = Players.LocalPlayer

local VehicleInterface = {}
VehicleInterface.__index = VehicleInterface

type VehicleInterface = VehicleTypes.VehicleInterface

function VehicleInterface.new(vehicle: VehicleTypes.ClientVehicle)
	local self: VehicleInterface = setmetatable({}, VehicleInterface) :: any

	self.Vehicle = vehicle

	self.Instance = UI:Clone()
	self.Instance.Parent = player.PlayerGui

	self.Speedometer = Speedometer.new(vehicle, self.Instance.Speedometer)
	SpeedEffect.new(vehicle, self.Instance)

	self.CursorInstance = self.Instance.Cursor
	self._cursorTransparency = self.Instance.Cursor.BackgroundTransparency

	local trove = Trove.new()

	self.Instance.Debug.Visible = RunService:IsStudio()
	if self.Instance.Debug.Visible then
		self.Instance.Debug.Car.Driveshaft.Front.Visible = self.Vehicle.Tune.Drivetrain ~= "RWD"
		self.Instance.Debug.Car.Driveshaft.Rear.Visible = self.Vehicle.Tune.Drivetrain ~= "FWD"

		trove:Connect(RunService.Heartbeat, function() UpdateDebug(self) end)
	end

	trove:Connect(RunService.Heartbeat, function() UpdateInputs(self) end)
	trove:BindToRenderStep("CursorUpdate", Enum.RenderPriority.Camera.Value - 1, function() UpdateCursor(self) end)
	trove:Add(function() UserInputService.MouseIconEnabled = true end)
	trove:AttachToInstance(self.Instance)

	return self
end

function UpdateCursor(self: VehicleInterface)
	UserInputService.MouseIconEnabled = not self.Vehicle.InputController.MouseSteerOn
	self.CursorInstance.Visible = self.Vehicle.InputController.MouseSteerOn
	if self.Vehicle.InputController.MouseSteerOn then
		self.CursorInstance.Position =
			UDim2.fromScale(self.Vehicle.InputController.MousePosition.X, self.Vehicle.InputController.MousePosition.Y)
		self.CursorInstance.BackgroundTransparency = 1
			- (1 - self._cursorTransparency) * (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and 0.5 or 1)
	end
end

function UpdateDebug(self: VehicleInterface)
	local car = self.Instance.Debug.Car
	for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
		local tireFill = car.Tires:FindFirstChild(wheel.Instance.Name).Fill :: Frame
		tireFill.Size = UDim2.fromScale(1, wheel.Tire.Health)
		tireFill.BackgroundColor3 = Color3.fromHSV(0, wheel.Tire.Stress, 1)

		local brakeFill = car.Brakes:FindFirstChild(wheel.Instance.Name).Fill :: Frame
		brakeFill.BackgroundColor3 =
			Color3.fromHSV(0, math.clamp(MapToRange(wheel.BrakeDisk.Temperature, 80, 200), 0, 1), 1)
	end
	car.Driveshaft.GroupColor3 = Color3.fromHSV(0, math.clamp(self.Vehicle.Engine.DriveshaftStress, 0, 1), 1)

	local info = self.Instance.Debug.Info
	info.Health.Text = string.format("Health: %.3f %%", self.Vehicle.Engine.Health * 100)
	info.Temperature.Text = string.format("Temperature: %.1f °C", self.Vehicle.Engine.Temperature)
end

function UpdateInputs(self: VehicleInterface)
	self.Instance.Inputs.Visible = SettingsController:GetSetting("ShowInputs")
	if self.Instance.Inputs.Visible then
		self.Instance.Inputs.Steering.Left.Fill.Size = UDim2.fromScale(math.max(-self.Vehicle.Steering, 0), 1)
		self.Instance.Inputs.Steering.Right.Fill.Size = UDim2.fromScale(math.max(self.Vehicle.Steering, 0), 1)

		self.Instance.Inputs.Pedals.Throttle.Fill.Size = UDim2.fromScale(1, self.Vehicle.Throttle)
		self.Instance.Inputs.Pedals.Brake.Fill.Size = UDim2.fromScale(1, self.Vehicle.Brake)
		self.Instance.Inputs.Pedals.Clutch.Fill.Size = UDim2.fromScale(1, self.Vehicle.Clutch)
	end
end

function VehicleInterface.Destroy(self: VehicleInterface) self.Instance:Destroy() end

return VehicleInterface
