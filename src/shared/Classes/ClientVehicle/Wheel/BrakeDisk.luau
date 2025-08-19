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

function ClientBrakeDisk.new(wheel: VehicleTypes.ClientWheel, instance: BasePart)
	local self: ClientBrakeDisk = setmetatable(BaseBrakeDisk.new(wheel, instance), ClientBrakeDisk) :: any

	self._serverInstance = self.Instance
	self._startColor = self.Instance.Color

	self.Instance = self._serverInstance:Clone()
	self.Instance.Parent = self._serverInstance
	MakeWeld(self.Instance, self._serverInstance)

	self._serverInstance.Transparency = 1

	self._conn = RunService.Heartbeat:Connect(function(deltaTime) self:Update(deltaTime) end)
	self._task = task.spawn(function()
		while task.wait(1 / 10) do
			self._Remote:FireServer(self.Temperature, self.Instance.Color)
		end
	end)

	return self
end

function ClientBrakeDisk.Update(self: ClientBrakeDisk, deltaTime: number)
	local GlobalTemperature = game.Workspace:GetAttribute("GlobalTemperature")

	local rotSpeed = self.Wheel.Instance.AssemblyAngularVelocity.Magnitude / 360
	self.Temperature += self.Wheel.Instance["#BV"].MotorMaxTorque * rotSpeed * deltaTime
	self.Temperature = Lerp(self.Temperature, GlobalTemperature, deltaTime * 0.3)

	local colorDelta = math.clamp(MapToRange(self.Temperature, 80, 200), 0, 1)
	self.Instance.Color = self._startColor:Lerp(Color3.new(1, 0.3, 0), colorDelta)
end

function ClientBrakeDisk.Destroy(self: ClientBrakeDisk)
	self._conn:Disconnect()
	task.cancel(self._task)
	self.Instance:Destroy()
	self._serverInstance.Transparency = 0
end

return ClientBrakeDisk
