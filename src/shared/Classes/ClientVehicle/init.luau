-- local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CameraController = require(script.CameraController)
local Enums = require(ReplicatedStorage.Shared.Enums)
-- local CreateEditableMesh =
-- 	require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
-- local DeformationController = require(script.DeformationController)
local Component = require(script.Parent.Component)
local Engine = require(script.Engine)
local InputController = require(script.InputController)
local RComponent = require(script.Parent.RComponent)
local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)
local Signal = require(ReplicatedStorage.Shared.Utils.Signal)
local SoundController = require(script.SoundController)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Transmission = require(script.Transmission)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleInterface = require(ReplicatedStorage.Shared.UI.VehicleInterface)
local VehiclePackets = require(ReplicatedStorage.Shared.Packets.VehiclePackets)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)
local VehicleUtil = require(ReplicatedStorage.Shared.Utils.VehicleUtil)

local player = Players.LocalPlayer

local ClientVehicle = { set = {}, get = {} }
ClientVehicle.__extends = RComponent.Instanced.Client

type ClientVehicle = VehicleTypes.ClientVehicle

type ClientVehicleImpl = {
	lastVelocity: Vector3,
	controllers: {
		{
			Name: string,
			Module: VehicleTypes.VehicleControllerImplType,
			Object: VehicleTypes.VehicleControllerType,
		}
	},
	controllersRE: RemoteEvent,
	controllersURE: UnreliableRemoteEvent,
} & ClientVehicle

function ClientVehicle.new(instance: Instance): ClientVehicle
	local self: ClientVehicleImpl = Component(
		ClientVehicle,
		RComponent.Instanced.Client.new(instance)
	) :: any

	VehicleUtil.Setup(self, instance)
	-- self.MeshParts = {}
	-- self.Meshes = {}
	-- self.Textures = {}
	self.IsSitting = false
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
	self.URE = self.Instance:WaitForChild("VehicleURE") :: UnreliableRemoteEvent
	self.RE = self.Instance:WaitForChild("VehicleRE") :: RemoteEvent
	self.RF = self.Instance:WaitForChild("VehicleRF") :: RemoteFunction
	self.WeightPart = self.Instance.Body:WaitForChild("WeightPart") :: Part
	self.lastVelocity = Vector3.new()

	local trove = Trove.new()
	trove:AttachToInstance(self.Instance.DriveSeat)

	self.DriverChanged = trove:Construct(Signal)
	self.IgnitionStateChanged = trove:Construct(Signal)
	self.SittingChanged = self:GetPropertyChangedSignal("IsSitting")
	self.PlayerSeated = trove:Construct(Signal)
	self.PlayerLeaved = trove:Construct(Signal)

	InitializeSeats(self)
	-- InitializeBody(self)

	self.Engine = Engine.new(self)
	self.Transmission = Transmission.new(self)

	-- Get server data
	Serialization.ApplyPacket(
		VehiclePackets.Init,
		self.RF:InvokeServer(Enums.VehicleAction.InvokeInitPacket),
		self
	)
	self.Fuel *= self.Tune.FuelCapacity

	VehicleUtil.InitializeWheels(self)
	self.SoundController = SoundController.new(self)
	-- self.DeformationController = DeformationController.new(self)

	InitializeControllers(self)

	trove:Connect( -- Driver changed signal
		self:GetPropertyChangedSignal("Driver"),
		function() self.DriverChanged:FireDeferred(self.Driver) end
	)
	trove:Connect( -- Ignition state changed signal
		self:GetPropertyChangedSignal("IgnitionState"),
		function() self.IgnitionStateChanged:FireDeferred(self.IgnitionState) end
	)
	trove:Connect( -- Update connection
		RunService.Heartbeat,
		function(deltaTime) Update(self, deltaTime) end
	)

	-- Replication
	trove:Connect(
		self.URE.OnClientEvent,
		function(buf) Replicate(self, buf) end
	)
	trove:Add(task.spawn(function()
		while task.wait(1 / 30) do
			Replicate(self)
		end
	end))

	return self
end

function Seated(
	self: ClientVehicleImpl,
	seatedPlayer: Player,
	seat: VehicleSeat | Seat
)
	if seat :: any == self.Instance.DriveSeat then
		self.Driver = seatedPlayer
	else
		self.Passengers[seat] = seatedPlayer
	end
	self.PlayerSeated:FireDeferred(seatedPlayer, seat)

	if seatedPlayer ~= player then return end
	togglePrompts(self, false)
	self.IsSitting = true

	if seat :: any ~= self.Instance.DriveSeat then return end

	-- Remove Flip Force
	if self.Instance.DriveSeat:FindFirstChild("Flip") then
		self.Instance.DriveSeat.Flip.Enabled = false
	end

	self.InputController = InputController.new(self)
	self.CameraController = CameraController.new(self)
	self.Interface = VehicleInterface.new(self)
end

function Leaved(
	self: ClientVehicleImpl,
	leavedPlayer: Player,
	seat: VehicleSeat | Seat
)
	if seat :: any == self.Instance.DriveSeat then
		self.Driver = nil
	else
		self.Passengers[seat] = nil
	end
	self.PlayerLeaved:FireDeferred(leavedPlayer, seat)

	if leavedPlayer ~= player then return end
	togglePrompts(self, true)
	self.IsSitting = false

	if seat :: any ~= self.Instance.DriveSeat then return end

	self.InputController:Destroy()
	self.CameraController:Destroy()
	self.Interface:Destroy()
end

function ClientVehicle.Leave(self: ClientVehicleImpl)
	assert(
		player.Character,
		"Error when leaving the vehicle: player's character is nil"
	)

	local humanoid =
		player.Character:FindFirstChildOfClass("Humanoid") :: Humanoid
	local seat = humanoid.SeatPart
	if not seat then return end

	local RE = (seat :: any)._SeatRE :: RemoteEvent
	RE:FireServer()

	RE.OnClientEvent:Wait()
	player.Character:PivotTo(
		CFrame.new(((seat :: any).LeavePosition :: Attachment).WorldPosition)
	)
end

function togglePrompts(self: ClientVehicleImpl, enabled: boolean)
	local seats = self.Instance.Seats:GetChildren()
	table.insert(seats, self.Instance.DriveSeat)

	for _, seat in seats do
		if not seat:IsA("VehicleSeat") and not seat:IsA("Seat") then
			continue
		end

		local prompt = (seat :: any).PromptAttachment.ProximityPrompt :: ProximityPrompt
		if seat.Occupant then
			prompt.Enabled = false
		else
			prompt.Enabled = enabled
		end
	end
end

-- function InitializeBody(self: ClientVehicleImpl)
-- 	local taskCount = 0
-- 	for _, v in self.Instance.Body:GetDescendants() do
-- 		if not v:IsA("MeshPart") or not v:HasTag("Deformable") then continue end

-- 		task.spawn(function()
-- 			local texture
-- 			if v.TextureContent.SourceType ~= Enum.ContentSourceType.None then
-- 				texture =
-- 					AssetService:CreateEditableImageAsync(v.TextureContent)
-- 			end

-- 			local mesh = CreateEditableMesh(v)
-- 			if texture then
-- 				v.TextureContent = Content.fromObject(texture)
-- 				self.Textures[v] = texture
-- 			end

-- 			self.Meshes[v] = mesh

-- 			local index = assert(tonumber(string.match(v.Name, "%.(%d+)$")))
-- 			self.MeshParts[index] = v

-- 			taskCount -= 1
-- 		end)
-- 		taskCount += 1
-- 	end

-- 	repeat
-- 		task.wait()
-- 	until taskCount == 0
-- end

function InitializeSeats(self: ClientVehicleImpl)
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

				local seatedPlayer =
					Players:GetPlayerFromCharacter(character :: Model)
				if not seatedPlayer then return end

				Seated(self, seatedPlayer, seat)
			else
				local leavedPlayer = seat == self.Instance.DriveSeat :: any
						and self.Driver
					or self.Passengers[seat]
				Leaved(self, leavedPlayer, seat)
			end
		end)
	end
end

function InitializeControllers(self: ClientVehicleImpl)
	self.controllers = {}
	self.controllersRE =
		self.Instance:FindFirstChild("_ControllersRE") :: RemoteEvent
	self.controllersURE =
		self.Instance:FindFirstChild("_ControllersURE") :: UnreliableRemoteEvent

	local function onDataReceived(name: string, ...)
		local controller = self:GetController(name)
		if controller and controller.DataReceived then
			(controller :: any):DataReceived(...)
		end
	end

	self.controllersRE.OnClientEvent:Connect(onDataReceived)
	self.controllersURE.OnClientEvent:Connect(onDataReceived)

	for _, v in script.Controllers:GetChildren() do
		if not v:IsA("ModuleScript") then continue end

		local module = require(v) :: VehicleTypes.VehicleControllerImplType
		AddController(self, v.Name, module, module.new(self))
	end
end

function AddController(
	self: ClientVehicleImpl,
	name: string,
	module: any,
	object: any
)
	table.insert(
		self.controllers,
		{ Name = name, Module = module, Object = object }
	)
	return object
end

function ClientVehicle.GetController(self: ClientVehicleImpl, name: string)
	local value = TableUtil.Find(
		self.controllers,
		function(v) return v.Name == name end
	)
	return value and value.Object
end

function ClientVehicle.SendData(
	self: ClientVehicleImpl,
	controller: VehicleTypes.VehicleControllerType,
	...
)
	local value = TableUtil.Find(
		self.controllers,
		function(v) return v.Module.Is(controller) end
	)
	if not value then
		warn("Controller not found")
		return
	end

	self.controllersRE:FireServer(value.Name, ...)
end

-- TODO: Drivetrain Initialize

function UpdateWheels(self: ClientVehicleImpl, deltaTime: number)
	for _, wheel: VehicleTypes.ClientWheel in self.Wheels :: any do
		wheel:Update(deltaTime)
	end

	self.TCSActive = false
	self.ABSActive = false
	self.ESCActive = false
end

function UpdateMileage(self: ClientVehicleImpl, deltaTime: number)
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

function Replicate(self: ClientVehicleImpl, buf: buffer?)
	if self.IsDriven then
		self.URE:FireServer(
			Serialization.Serialize(VehiclePackets.Update, self)
		)
	elseif buf then
		VehicleUtil.Replicate(self, buf)
	end
end

function Update(self: ClientVehicleImpl, deltaTime: number)
	deltaTime = math.max(deltaTime, 0.001)
	self.Acceleration = (self.Velocity - self.lastVelocity) * (1 / deltaTime)
	self.lastVelocity = self.Velocity

	if not self.IsDriven then return end

	UpdateWheels(self, deltaTime)
	self.Transmission:Update()
	self.Engine:Update(deltaTime)
	UpdateMileage(self, deltaTime)
end

function ClientVehicle.get.IsOwned(self: ClientVehicleImpl)
	return self.Owner == player
end

function ClientVehicle.get.IsDriven(self: ClientVehicleImpl)
	return self.Driver == player
end

function ClientVehicle.get.CFrame(self: ClientVehicle)
	return self.WeightPart.CFrame
end

function ClientVehicle.get.Velocity(self: ClientVehicle)
	return self.WeightPart.AssemblyLinearVelocity
end

function ClientVehicle.get.AngularVelocity(self: ClientVehicle)
	return self.WeightPart.AssemblyAngularVelocity
end

function ClientVehicle.get.Center(self: ClientVehicle)
	return VehicleUtil.GetCenter(self)
end

function ClientVehicle.set.CFrame(self: ClientVehicle, cframe: CFrame)
	self.Instance:PivotTo(cframe)
end

return table.freeze(ClientVehicle :: any) :: {
	new: (instance: Instance) -> ClientVehicle,
}
