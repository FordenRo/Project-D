local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local SpeedEffect = require(script.SpeedEffect)
local Speedometer = require(script.Speedometer)
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
	self.SpeedEffect = SpeedEffect.new(vehicle, self.Instance)

	self.CursorInstance = self.Instance.Cursor
	self._CursorTransparency = self.Instance.Cursor.BackgroundTransparency

	self._conn = RunService.Heartbeat:Connect(function() self:UpdateTires() end)
	RunService:BindToRenderStep(
		"CursorUpdate",
		Enum.RenderPriority.Camera.Value - 1,
		function() self:UpdateCursor() end
	)

	return self
end

function VehicleInterface.UpdateCursor(self: VehicleInterface)
	UserInputService.MouseIconEnabled = not self.Vehicle.InputController.MouseSteerOn
	self.CursorInstance.Visible = self.Vehicle.InputController.MouseSteerOn
	if self.Vehicle.InputController.MouseSteerOn then
		self.CursorInstance.Position =
			UDim2.fromScale(self.Vehicle.InputController.MousePosition.X, self.Vehicle.InputController.MousePosition.Y)
		self.CursorInstance.BackgroundTransparency = 1
			- (1 - self._CursorTransparency) * (UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) and 0.5 or 1)
	end
end

function VehicleInterface.UpdateTires(self: VehicleInterface)
	for _, wheel in self.Vehicle.Wheels do
		local tireUI = self.Instance.Tires[wheel.Instance.Name]
		tireUI.First.Second.Size = UDim2.new(
			1,
			0,
			math.clamp(
				1
					- (wheel.Tire.Temperature - 40)
						/ ((wheel.IsFront and wheel.Vehicle.Tune.TireFMaxTemp or wheel.Vehicle.Tune.TireRMaxTemp) - 40),
				0,
				1
			),
			0
		)
		tireUI.BackgroundColor3 = Color3.fromHSV(0, wheel.Tire.Stress, 1)
		tireUI.BackgroundTransparency = 0.8 - 0.3 * wheel.Tire.Stress
	end
end

function VehicleInterface.Destroy(self: VehicleInterface)
	self._conn:Disconnect()
	self.Speedometer:Destroy()
	self.Instance:Destroy()
	RunService:UnbindFromRenderStep("CursorUpdate")
	UserInputService.MouseIconEnabled = true
end

return VehicleInterface
