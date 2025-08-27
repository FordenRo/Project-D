local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseVehicle = require(script.Parent.BaseVehicle)
local CreateEditableMesh = require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local DeformationController = require(script.DeformationController)
local Engine = require(script.Engine)
local Exhaust = require(script.Exhaust)
local InputController = require(script.InputController)
local Lights = require(script.Lights)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local SoundController = require(script.SoundController)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local UpdateSteering = require(script.UpdateSteering)
local UpdateTransmission = require(script.UpdateTransmission)
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

	SoundController.new(self)
	Exhaust.new(self)
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

function Seated(self: ClientVehicle, seatedPlayer: Player, asDriver: boolean)
	if seatedPlayer ~= player then return end
	togglePrompts(self, false)

	self.IsDriven = asDriver and seatedPlayer == player
	if not self.IsDriven then return end

	HideCharacter(self)
	InitializePlugins(self)

	self.InputController = InputController.new(self)
	self.DeformationController = DeformationController.new(self)
	self.Interface = VehicleInterface.new(self)
end

function Leaved(self: ClientVehicle, leavedPlayer: Player, asDriver: boolean)
	if leavedPlayer ~= player then return end
	togglePrompts(self, true)
end

function togglePrompts(self: ClientVehicle, enabled: boolean)
	for _, seat in self.Instance.Seats:GetChildren() do
		if not seat:IsA("VehicleSeat") then continue end

		seat.ProximityPrompt.Enabled = enabled
	end

	self.Instance.DriveSeat.ProximityPrompt.Enabled = enabled
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
	for _, seat in self.Instance.Seats:GetChildren() do
		if not seat:IsA("VehicleSeat") then continue end

		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			if seat.Occupant then
				local character = seat.Occupant.Parent
				if not character then return end

				local seatedPlayer = Players:GetPlayerFromCharacter(character)
				if not seatedPlayer then return end

				self.Passengers[seat] = seatedPlayer
				Seated(self, seatedPlayer, false)
			else
				local leavedPlayer = self.Passengers[seat]
				self.Passengers[seat] = nil
				Leaved(self, leavedPlayer, false)
			end
		end)
	end

	self.Instance.DriveSeat:GetPropertyChangedSignal("Occupant"):Connect(function()
		if self.Instance.DriveSeat.Occupant then
			local character = self.Instance.DriveSeat.Occupant.Parent
			if not character then return end

			local seatedPlayer = Players:GetPlayerFromCharacter(character)
			if not seatedPlayer then return end

			self.Driver = seatedPlayer
			Seated(self, seatedPlayer, true)
		else
			if not self.Driver then return end

			local leavedPlayer = self.Driver
			self.Driver = nil
			Leaved(self, leavedPlayer, true)
		end
	end)
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
	self._ClutchPressing = false
	self._DriveWheelSpeed = 0
	self._OldVelocity = Vector3.new()
	self._MaxSpin = 0
	self.WeightPart = self.Instance.Body.WeightPart
end

function ClientVehicle.InitializeWheels(self: ClientVehicle) BaseVehicle.InitializeWheels(self, Wheel) end

function InitializePlugins(self: ClientVehicle)
	for _, plugin in ReplicatedStorage.Shared.Vehicle.Plugins:GetChildren() do
		local pluginClass = require(plugin) :: any
		if pluginClass and pluginClass.new then self.Plugins[plugin.Name] = pluginClass.new(self) end
	end
end

-- Hides character for a while
function HideCharacter(self: ClientVehicle)
	for _, v in (player.Character :: Model):GetDescendants() do
		if not v:IsA("BasePart") then continue end

		v.Transparency = 1
	end
end

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
		if self.Tune.FlipType == "New" then
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

	for _, plugin in self.Plugins do
		plugin:Destroy()
	end

	for _, conn in self._cons do
		conn:Disconnect()
	end
	task.cancel(self._task)
end

return ClientVehicle
