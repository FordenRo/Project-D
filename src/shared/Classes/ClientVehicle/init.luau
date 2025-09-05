local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Aerodynamics = require(script.Aerodynamics)
local BaseVehicle = require(script.Parent.BaseVehicle)
local BodyController = require(script.BodyController)
local CameraController = require(script.CameraController)
local CreateEditableMesh = require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local DeformationController = require(script.DeformationController)
local Engine = require(script.Engine)
local ExhaustController = require(script.ExhaustController)
local InputController = require(script.InputController)
local InteriorController = require(script.InteriorController)
local Lights = require(script.Lights)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local SoundController = require(script.SoundController)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local UpdateSteering = require(script.UpdateSteering)
local UpdateTransmission = require(script.UpdateTransmission)
local VehicleConstants = require(ReplicatedStorage.Shared.Vehicle.VehicleConstants)
local VehicleInterface = require(ReplicatedStorage.Shared.UI.VehicleInterface)
local VehiclePacket = require(ReplicatedStorage.Shared.Packets.VehiclePacket)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local Wheel = require(script.Wheel)

local player = Players.LocalPlayer

local ClientVehicle = setmetatable({}, BaseVehicle)
ClientVehicle.__index = ClientVehicle

type ClientVehicle = VehicleTypes.ClientVehicle

function ClientVehicle.new(instance: Instance): ClientVehicle
	local self: VehicleTypes.ClientVehicle = setmetatable(BaseVehicle.new(instance), ClientVehicle) :: any

	self.MeshParts = {}
	self.Meshes = {}
	self.Textures = {}

	InitializeVariables(self)
	InitializeSeats(self)
	InitializeBody(self)

	self.Engine = Engine.new(self)
	self:InitializeWheels()

	self.SoundController = SoundController.new(self)
	ExhaustController.new(self)
	InteriorController.new(self)
	self.Lights = Lights.new(self)

	table.insert(self._cons, RunService.Heartbeat:Connect(function(deltaTime) Update(self, deltaTime) end))
	table.insert(self._cons, self._Remote.OnClientEvent:Connect(function(buf) Replicate(self, buf) end))
	self._task = task.spawn(function()
		while task.wait(1 / 30) do
			Replicate(self)
		end
	end)

	return self
end

function Seated(self: ClientVehicle, seatedPlayer: Player, seat: VehicleSeat | Seat)
	if seat :: any == self.Instance.DriveSeat then
		self.Driver = seatedPlayer
	else
		self.Passengers[seat] = seatedPlayer
	end

	if seatedPlayer ~= player then return end
	togglePrompts(self, false)

	if seat :: any ~= self.Instance.DriveSeat then return end
	self.IsDriven = true
	self._DrivenChangedEvent:Fire(true)

	self.InputController = InputController.new(self)
	self.CameraController = CameraController.new(self)
	self.DeformationController = DeformationController.new(self)
	BodyController.new(self)
	Aerodynamics.new(self)
	self.Interface = VehicleInterface.new(self)
end

function Leaved(self: ClientVehicle, leavedPlayer: Player, seat: VehicleSeat | Seat)
	if seat :: any == self.Instance.DriveSeat then
		self.Driver = nil
	else
		self.Passengers[seat] = nil
	end

	if leavedPlayer ~= player then return end
	togglePrompts(self, true)

	if seat :: any ~= self.Instance.DriveSeat then return end
	self.IsDriven = false
	self._DrivenChangedEvent:Fire(false)

	self.InputController:Destroy()
	self.CameraController:Destroy()
	self.Interface:Destroy()
end

function ClientVehicle.Leave(self: ClientVehicle)
	local humanoid = player.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local seat = humanoid.SeatPart
	if not seat then return end

	local RE = seat._SeatRE :: RemoteEvent
	RE:FireServer()

	RE.OnClientEvent:Wait()
	player.Character:PivotTo(CFrame.new(((seat :: any).LeavePosition :: Attachment).WorldPosition))
end

function togglePrompts(self: ClientVehicle, enabled: boolean)
	local seats = self.Instance.Seats:GetChildren()
	table.insert(seats, self.Instance.DriveSeat)

	for _, seat in seats do
		if not seat:IsA("VehicleSeat") and not seat:IsA("Seat") then continue end

		local prompt = seat.PromptAttachment.ProximityPrompt :: ProximityPrompt
		if seat.Occupant then
			prompt.Enabled = false
		else
			prompt.Enabled = enabled
		end
	end
end

function InitializeBody(self: ClientVehicle)
	local taskCount = 0
	for _, v in self.Instance.Body:GetDescendants() do
		if not v:IsA("MeshPart") or not v:HasTag("Deformable") then continue end

		task.spawn(function()
			local texture
			if v.TextureContent.SourceType ~= Enum.ContentSourceType.None then
				texture = AssetService:CreateEditableImageAsync(v.TextureContent)
			end

			local mesh = CreateEditableMesh(v)
			if texture then
				v.TextureContent = Content.fromObject(texture)
				self.Textures[v] = texture
			end

			self.Meshes[v] = mesh
			table.insert(self.MeshParts, v)

			taskCount -= 1
		end)
		taskCount += 1
	end

	repeat
		task.wait()
	until taskCount == 0
end

function InitializeSeats(self: ClientVehicle)
	local seats = self.Instance.Seats:GetChildren()
	table.insert(seats, self.Instance.DriveSeat)

	for _, seat in seats do
		if not seat:IsA("VehicleSeat") and not seat:IsA("Seat") then continue end

		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant then
				local character = seat.Occupant.Parent
				if not character then return end

				local seatedPlayer = Players:GetPlayerFromCharacter(character)
				if not seatedPlayer then return end

				Seated(self, seatedPlayer, seat)
			else
				local leavedPlayer = seat == self.Instance.DriveSeat and self.Driver or self.Passengers[seat]
				Leaved(self, leavedPlayer, seat)
			end
		end)
	end
end

function InitializeVariables(self: ClientVehicle)
	self.BrakeForce = {
		Front = self.Tune.BrakeForce * 9.80665 * Units.Force_N * self.Tune.BrakeBias,
		Rear = self.Tune.BrakeForce * 9.80665 * Units.Force_N * (1 - self.Tune.BrakeBias),
	}
	self.PBrakeForce = {
		Front = self.Tune.PBrakeForce * 9.80665 * Units.Force_N * self.Tune.PBrakeBias,
		Rear = self.Tune.PBrakeForce * 9.80665 * Units.Force_N * (1 - self.Tune.PBrakeBias),
	}
	self._cons = {}
	self._ShiftUp = false
	self._ShiftDown = false
	self._DriveWheelSpeed = 0
	self._OldVelocity = Vector3.new()
	self._MaxSpin = 0
	self._DrivenChangedEvent = Instance.new("BindableEvent")
	self.DrivenChanged = self._DrivenChangedEvent.Event
	self.WeightPart = self.Instance.Body.WeightPart
end

function ClientVehicle.InitializeWheels(self: ClientVehicle) BaseVehicle.InitializeWheels(self, Wheel) end

-- TODO: Drivetrain Initialize

-- TODO: Steering Initialize
-- function ClientVehicle.InitSteeringAuto(self: ClientVehicle)
-- 	self.SteerOuter = (self.Tune.LockToLock * 180) / self.Tune.SteerRatio
-- 	self.SteerInner = math.min(self.SteerOuter - (self.SteerOuter * (1 - self.Tune.Ackerman)), self.SteerOuter * 1.2)
-- end

function UpdateWheels(self: ClientVehicle)
	local count = #self.Wheels
	local driveCount = 0

	local data: VehicleTypes.ClientWheelSharedData = {
		TCSAmt = 0,
		ABSAmt = 0,
		ESCAmt = 0,
		TCSCount = 0,
		ABSCount = 0,
		ESCCount = 0,
		Rotation = 0,
		MaxSpin = 0,
		DriveWheelSpeed = 0,
	}
	for _, wheel in self.Wheels :: { VehicleTypes.ClientWheel } do
		wheel:Update(data)

		if wheel.IsDriven then
			driveCount += 1
		end
	end
	self._DriveWheelSpeed = data.DriveWheelSpeed / driveCount

	-- Wheel speeds
	self._MaxSpin = data.MaxSpin
	self.AverageRotSpeed = data.Rotation / count
	self.TCSActive = false
	self.ABSActive = false
	self.ESCActive = false
end

function UpdateMileage(self: ClientVehicle, deltaTime: number)
	local speed = 0
	local count = 0
	for _, wheel in self.Wheels do
		if not wheel.IsFront then continue end

		speed += math.abs(
			wheel.Instance.CFrame:VectorToObjectSpace(wheel.Instance.AssemblyAngularVelocity).X
				* (wheel.Instance.Size.Y / 2)
		)
		count += 1
	end
	self.Mileage += speed / count * (Units.Length_mm / 1000) * deltaTime
end

-- TODO: Flip function

function Replicate(self: ClientVehicle, buf: buffer?)
	if self.IsDriven then
		self._Remote:FireServer(Serialization.Serialize(VehiclePacket, self))
	elseif buf then
		self:_Replicate(buf)
	end
end

function Update(self: ClientVehicle, deltaTime: number)
	self.Center = self:GetCenter()
	self.Velocity = self.WeightPart.AssemblyLinearVelocity
	self.AngularVelocity = self.WeightPart.AssemblyAngularVelocity
	self.Acceleration = (self.Velocity - self._OldVelocity) * (1 / deltaTime)
	self._OldVelocity = self.Velocity

	if not self.IsDriven then return end

	UpdateWheels(self)
	UpdateSteering(self, deltaTime)
	UpdateTransmission(self)
	self.Engine:Update(deltaTime)
	UpdateMileage(self, deltaTime)
end

function ClientVehicle.Destroy(self: ClientVehicle)
	--Remove Flip Force
	if self.Instance.DriveSeat:FindFirstChild("Flip") then
		if VehicleConstants.FlipType == "New" then
			self.Instance.DriveSeat.Flip.Enabled = false
		else
			self.Instance.DriveSeat.Flip.MaxTorque = 0
		end
	end

	for _, wheel in self.Wheels :: { VehicleTypes.ClientWheel } do
		wheel:Destroy()
	end

	self.Engine:Destroy()
	self.InputController:Destroy()
	self.Interface:Destroy()
	self.Lights:Destroy()

	for _, conn in self._cons do
		conn:Disconnect()
	end
	task.cancel(self._task)
end

return ClientVehicle
