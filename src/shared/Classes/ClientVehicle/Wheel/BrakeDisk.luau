local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BaseBrakeDisk = require(ReplicatedStorage.Shared.Classes.BaseBrakeDisk)
local Lerp = require(ReplicatedStorage.Shared.Utils.Lerp)
local MakeWeld = require(ReplicatedStorage.Shared.Utils.MakeWeld)
local MapToRange = require(ReplicatedStorage.Shared.Utils.MapToRange)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local ClientBrakeDisk = setmetatable({}, BaseBrakeDisk)
ClientBrakeDisk.__index = ClientBrakeDisk

type ClientBrakeDisk = VehicleTypes.ClientBrakeDisk

function ClientBrakeDisk.new(wheel: VehicleTypes.ClientWheel, instance: BasePart): ClientBrakeDisk
	local self: ClientBrakeDisk = setmetatable(BaseBrakeDisk.new(wheel, instance), ClientBrakeDisk) :: any

	self._serverInstance = self.Instance
	self._serverSound = self.Sound
	self._startColor = self.Instance.Color
	self.Volume = 0

	self.Instance = self._serverInstance:Clone()
	self.Instance.Parent = self._serverInstance
	MakeWeld(self.Instance, self._serverInstance)

	self.Sound = self._serverSound:Clone() :: any
	self.Sound.Volume = 0
	self.Sound.Parent = self._serverSound

	self._serverSound.SoundId = ""
	self._serverInstance.Transparency = 1

	self._conn = RunService.Heartbeat:Connect(function(deltaTime) Update(self, deltaTime) end)
	self._task = task.spawn(function()
		while task.wait(1 / 10) do
			self._Remote:FireServer(
				self.Temperature,
				self.Instance.Color,
				self.Sound.Volume,
				self.Sound.PitchEffect.Octave
			)
		end
	end)

	return self
end

function Update(self: ClientBrakeDisk, deltaTime: number)
	local GlobalTemperature = game.Workspace:GetAttribute("GlobalTemperature") :: number

	local inBrake = self.Wheel.Vehicle.Brake :: number > 0 or self.Wheel.Vehicle.PBrake
	local rotSpeed = self.Wheel.Instance.AssemblyAngularVelocity.Magnitude / 360
	self.Sound.Playing = true
	if inBrake then
		self.Temperature += self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed * deltaTime
		self.Volume = Lerp(self.Volume, self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed ^ 0.8 / 5000, deltaTime * 5)
		self.Sound.PitchEffect.Octave = 0.9 + self.Wheel.Instance.BV.MotorMaxTorque * rotSpeed ^ 0.8 / 1000
	else
		self.Volume = Lerp(self.Volume, 0, deltaTime * 5)
	end
	self.Temperature = Lerp(self.Temperature, GlobalTemperature, deltaTime * 0.3)
	self.Sound.Volume = self.Volume

	local colorDelta = math.clamp(MapToRange(self.Temperature, 80, 200), 0, 1)
	self.Instance.Color = self._startColor:Lerp(Color3.new(1, 0.3, 0), colorDelta)
end

function ClientBrakeDisk.Destroy(self: ClientBrakeDisk)
	self._conn:Disconnect()
	task.cancel(self._task)
	self._serverSound.SoundId = self.Sound.SoundId
	self._serverInstance.Transparency = 0
	self.Sound:Destroy()
	self.Instance:Destroy()
end

return ClientBrakeDisk
