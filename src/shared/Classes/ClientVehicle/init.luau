local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Aerodynamics = require(script.Aerodynamics)
local BaseVehicle = require(script.Parent.BaseVehicle)
local BodyController = require(script.BodyController)
local CameraController = require(script.CameraController)
local CreateEditableMesh =
	require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local DeformationController = require(script.DeformationController)
local Engine = require(script.Engine)
local ExhaustController = require(script.ExhaustController)
local InputController = require(script.InputController)
local InteriorController = require(script.InteriorController)
local Lights = require(script.Lights)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local SoundController = require(script.SoundController)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local UpdateTransmission = require(script.UpdateTransmission)
local VehicleConstants =
	require(ReplicatedStorage.Shared.Vehicle.VehicleConstants)
local VehicleInterface = require(ReplicatedStorage.Shared.UI.VehicleInterface)
local VehiclePacket = require(ReplicatedStorage.Shared.Packets.VehiclePacket)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local Wheel = require(script.Wheel)

local player = Players.LocalPlayer

local ClientVehicle = setmetatable({}, BaseVehicle)
ClientVehicle.__index = ClientVehicle

type ClientVehicle = VehicleTypes.ClientVehicle

function ClientVehicle.new(instance: Instance): ClientVehicle
	local self: VehicleTypes.ClientVehicle =
		setmetatable(BaseVehicle.new(instance), ClientVehicle) :: any

	self.MeshParts = {}
	self.Meshes = {}
	self.Textures = {}

	local trove = Trove.new()
	trove:AttachToInstance(instance)

	self.DriverChanged = trove:Construct(Signal)
	self.IgnitionStateChanged = trove:Construct(Signal)
	self.SittingChanged = trove:Construct(Signal)

	InitializeVariables(self)
	InitializeSeats(self)
	InitializeBody(self)

	self.Engine = Engine.new(self)
	self:InitializeWheels()

	self.SoundController = SoundController.new(self)
	self.DeformationController = DeformationController.new(self)
	ExhaustController.new(self)
	InteriorController.new(self)
	self.Lights = Lights.new(self)

	trove:Connect(
		RunService.Heartbeat,
		function(deltaTime) Update(self, deltaTime) end
	)
	trove:Connect(
		self._Remote.OnClientEvent,
		function(buf) Replicate(self, buf) end
	)
	trove:Add(task.spawn(function()
		while task.wait(1 / 30) do
			Replicate(self)
		end
	end))
	trove:Add(function()
		--Remove Flip Force
		if self.Instance.DriveSeat:FindFirstChild("Flip") then
			if VehicleConstants.FlipType == "New" then
				self.Instance.DriveSeat.Flip.Enabled = false
			else
				self.Instance.DriveSeat.Flip.MaxTorque = 0
			end
		end
	end)

	return self
end

function Seated(
	self: ClientVehicle,
	seatedPlayer: Player,
	seat: VehicleSeat | Seat
)
	if seat :: any == self.Instance.DriveSeat then
		self.Driver = seatedPlayer
		self.DriverChanged:Fire(seatedPlayer)
	else
		self.Passengers[seat] = seatedPlayer
	end
	BodyController.new(self, seatedPlayer, seat)

	if seatedPlayer ~= player then return end
	togglePrompts(self, false)
	self.IsSitting = true

	if seat :: any ~= self.Instance.DriveSeat then return end
	self.IsDriven = true

	self.InputController = InputController.new(self)
	self.CameraController = CameraController.new(self)
	Aerodynamics.new(self)
	self.Interface = VehicleInterface.new(self)
end

function Leaved(
	self: ClientVehicle,
	leavedPlayer: Player,
	seat: VehicleSeat | Seat
)
	if seat :: any == self.Instance.DriveSeat then
		self.Driver = nil
		self.DriverChanged:Fire(nil)
	else
		self.Passengers[seat] = nil
	end

	if leavedPlayer ~= player then return end
	togglePrompts(self, true)
	self.IsSitting = false

	if seat :: any ~= self.Instance.DriveSeat then return end
	self.IsDriven = false

	self.InputController:Destroy()
	self.CameraController:Destroy()
	self.Interface:Destroy()
end

function ClientVehicle.Leave(self: ClientVehicle)
	local humanoid =
		player.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local seat = humanoid.SeatPart
	if not seat then return end

	local RE = seat._SeatRE :: RemoteEvent
	RE:FireServer()

	RE.OnClientEvent:Wait()
	player.Character:PivotTo(
		CFrame.new(((seat :: any).LeavePosition :: Attachment).WorldPosition)
	)
end

function togglePrompts(self: ClientVehicle, enabled: boolean)
	local seats = self.Instance.Seats:GetChildren()
	table.insert(seats, self.Instance.DriveSeat)

	for _, seat in seats do
		if not seat:IsA("VehicleSeat") and not seat:IsA("Seat") then
			continue
		end

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
				texture =
					AssetService:CreateEditableImageAsync(v.TextureContent)
			end

			local mesh = CreateEditableMesh(v)
			if texture then
				v.TextureContent = Content.fromObject(texture)
				self.Textures[v] = texture
			end

			self.Meshes[v] = mesh

			local index = tonumber(string.match(v.Name, "%.(%d+)$"))
			self.MeshParts[index] = v

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
		if not seat:IsA("VehicleSeat") and not seat:IsA("Seat") then
			continue
		end

		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant then
				local character = seat.Occupant.Parent
				if not character then return end

				local seatedPlayer = Players:GetPlayerFromCharacter(character)
				if not seatedPlayer then return end

				Seated(self, seatedPlayer, seat)
			else
				local leavedPlayer = seat == self.Instance.DriveSeat
						and self.Driver
					or self.Passengers[seat]
				Leaved(self, leavedPlayer, seat)
			end
		end)
	end
end

function InitializeVariables(self: ClientVehicle)
	self.BrakeForce = {
		Front = self.Tune.BrakeForce
			* 9.80665
			* Units.Force_N
			* self.Tune.BrakeBias,
		Rear = self.Tune.BrakeForce
			* 9.80665
			* Units.Force_N
			* (1 - self.Tune.BrakeBias),
	}
	self.PBrakeForce = {
		Front = self.Tune.PBrakeForce
			* 9.80665
			* Units.Force_N
			* self.Tune.PBrakeBias,
		Rear = self.Tune.PBrakeForce
			* 9.80665
			* Units.Force_N
			* (1 - self.Tune.PBrakeBias),
	}
	self._ShiftUp = false
	self._ShiftDown = false
	self._OldVelocity = Vector3.new()
	self.WeightPart = self.Instance.Body.WeightPart
end

function ClientVehicle.InitializeWheels(self: ClientVehicle)
	BaseVehicle.InitializeWheels(self, Wheel)
end

-- TODO: Drivetrain Initialize

-- TODO: Steering Initialize
-- function ClientVehicle.InitSteeringAuto(self: ClientVehicle)
-- 	self.SteerOuter = (self.Tune.LockToLock * 180) / self.Tune.SteerRatio
-- 	self.SteerInner = math.min(self.SteerOuter - (self.SteerOuter * (1 - self.Tune.Ackerman)), self.SteerOuter * 1.2)
-- end

function UpdateWheels(self: ClientVehicle, deltaTime: number)
	for _, wheel in self.Wheels :: { VehicleTypes.ClientWheel } do
		wheel:Update(deltaTime)
	end

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
			wheel.Instance.CFrame:VectorToObjectSpace(
				wheel.Instance.AssemblyAngularVelocity
			).X * (wheel.Instance.Size.Y / 2)
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

	UpdateWheels(self, deltaTime)
	UpdateTransmission(self)
	self.Engine:Update(deltaTime)
	UpdateMileage(self, deltaTime)
end

return table.freeze({ new = ClientVehicle.new })
