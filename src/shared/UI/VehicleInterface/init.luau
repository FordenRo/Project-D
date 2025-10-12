--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MathUtil = require(ReplicatedStorage.Shared.Utils.MathUtil)
local SettingsController =
	require(ReplicatedStorage.Shared.Controllers.SettingsController)
local SpeedEffect = require(script.SpeedEffect)
local Speedometer = require(script.Speedometer)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local UI = ReplicatedStorage.UI.VehicleInterface
local player = Players.LocalPlayer

local VehicleInterface = {}
VehicleInterface.__index = VehicleInterface

type VehicleInterface = VehicleTypes.VehicleInterface

type VISlider = Frame & { Fill: Frame }
type VehicleInterfaceImpl = {
	cursorTransparency: number,
	cursorInstance: Frame,
	Instance: ScreenGui & {
		Cursor: Frame,
		Speedometer: Frame,
		Debug: Frame & {
			Info: Frame & {
				Health: TextLabel,
				Temperature: TextLabel,
			},
			Car: CanvasGroup & {
				Tires: Frame,
				Brakes: Frame,
				Driveshaft: CanvasGroup & { Front: Frame, Rear: Frame },
			},
		},
		Inputs: Frame & {
			Steering: Frame & { Left: VISlider, Right: VISlider },
			Pedals: Frame & {
				Throttle: VISlider,
				Brake: VISlider,
				Clutch: VISlider,
			},
		},
	},
} & VehicleInterface

function VehicleInterface.new(
	vehicle: VehicleTypes.ClientVehicle
): VehicleInterface
	local self: VehicleInterfaceImpl = setmetatable({}, VehicleInterface) :: any

	self.Vehicle = vehicle

	self.Instance = UI:Clone() :: any
	self.Instance.Parent = player.PlayerGui

	self.Speedometer = Speedometer.new(vehicle, self.Instance.Speedometer)
	SpeedEffect.new(vehicle, self.Instance)

	self.cursorInstance = self.Instance.Cursor
	self.cursorTransparency = self.Instance.Cursor.BackgroundTransparency

	local trove = Trove.new()

	self.Instance.Debug.Visible = RunService:IsStudio()
	if self.Instance.Debug.Visible then
		self.Instance.Debug.Car.Driveshaft.Front.Visible = self.Vehicle.Tune.Drivetrain
			~= "RWD"
		self.Instance.Debug.Car.Driveshaft.Rear.Visible = self.Vehicle.Tune.Drivetrain
			~= "FWD"

		trove:Connect(RunService.Heartbeat, function() UpdateDebug(self) end)
	end

	trove:Connect(RunService.Heartbeat, function() UpdateInputs(self) end)
	trove:BindToRenderStep(
		"CursorUpdate",
		Enum.RenderPriority.Camera.Value - 1,
		function() UpdateCursor(self) end
	)
	trove:Add(function() UserInputService.MouseIconEnabled = true end)
	trove:AttachToInstance(self.Instance)

	return self
end

function UpdateCursor(self: VehicleInterfaceImpl)
	UserInputService.MouseIconEnabled =
		not self.Vehicle.InputController.IsMouseSteerOn
	self.cursorInstance.Visible = self.Vehicle.InputController.IsMouseSteerOn
	if self.Vehicle.InputController.IsMouseSteerOn then
		self.cursorInstance.Position = UDim2.fromScale(
			self.Vehicle.InputController.MousePosition.X,
			self.Vehicle.InputController.MousePosition.Y
		)
		self.cursorInstance.BackgroundTransparency = 1
			- (1 - self.cursorTransparency)
				* (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and 0.5 or 1)
	end
end

function UpdateDebug(self: VehicleInterfaceImpl)
	local car = self.Instance.Debug.Car
	for _, wheel in self.Vehicle.Wheels :: { VehicleTypes.ClientWheel } do
		local tireFill = (
			car.Tires:FindFirstChild(wheel.Instance.Name) :: Frame
		):FindFirstChild("Fill") :: Frame
		tireFill.Size = UDim2.fromScale(1, wheel.Tire.Health)
		tireFill.BackgroundColor3 = Color3.fromHSV(0, wheel.Tire.Stress, 1)

		local brakeFill = (
			car.Brakes:FindFirstChild(wheel.Instance.Name) :: Frame
		):FindFirstChild("Fill") :: Frame
		brakeFill.BackgroundColor3 = Color3.fromHSV(
			0,
			math.clamp(MathUtil.Map(wheel.BrakeDisk.Temperature, 80, 200), 0, 1),
			1
		)
	end
	car.Driveshaft.GroupColor3 = Color3.fromHSV(
		0,
		math.clamp(self.Vehicle.Engine.DriveshaftStress, 0, 1),
		1
	)

	local info = self.Instance.Debug.Info
	info.Health.Text =
		string.format("Health: %.3f %%", self.Vehicle.Engine.Health * 100)
	info.Temperature.Text =
		string.format("Temperature: %.1f °C", self.Vehicle.Engine.Temperature)
end

function UpdateInputs(self: VehicleInterfaceImpl)
	self.Instance.Inputs.Visible = SettingsController:GetSetting("ShowInputs")
	if self.Instance.Inputs.Visible then
		self.Instance.Inputs.Steering.Left.Fill.Size =
			UDim2.fromScale(math.max(-self.Vehicle.Steering, 0), 1)
		self.Instance.Inputs.Steering.Right.Fill.Size =
			UDim2.fromScale(math.max(self.Vehicle.Steering, 0), 1)

		self.Instance.Inputs.Pedals.Throttle.Fill.Size =
			UDim2.fromScale(1, self.Vehicle.Throttle)
		self.Instance.Inputs.Pedals.Brake.Fill.Size =
			UDim2.fromScale(1, self.Vehicle.Brake)
		self.Instance.Inputs.Pedals.Clutch.Fill.Size =
			UDim2.fromScale(1, self.Vehicle.Clutch)
	end
end

function VehicleInterface.Destroy(self: VehicleInterfaceImpl)
	self.Instance:Destroy()
end

return table.freeze({ new = VehicleInterface.new })
