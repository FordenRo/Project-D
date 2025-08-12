local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Units = require(ReplicatedStorage.Shared.Utils.Units)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local SettingsController = require(player.PlayerScripts.Client.Controllers.SettingsController)

return function(self: VehicleTypes.ClientVehicle, deltaTime: number)
	deltaTime = (60 / (1 / deltaTime))
	local controller = self._LastInputWasGamepad or (self.Tune.MSteerUsesContlr and self.MouseSteerOn or false)
	local SteerSpeed
	local ReturnSpeed
	if controller then
		SteerSpeed = self.Tune.ContlrSteerSpeed > 0 and self.Tune.ContlrSteerSpeed or self.Tune.SteerSpeed
		ReturnSpeed = self.Tune.ContlrReturnSpeed > 0 and self.Tune.ContlrReturnSpeed or self.Tune.ReturnSpeed
	else
		SteerSpeed = self.Tune.SteerSpeed
			* (
				1
				- math.min(
					self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / self.Tune.SteerSpeedDecay,
					1 - (self.Tune.MinSteerSpeed / 100)
				)
			)
		ReturnSpeed = self.Tune.ReturnSpeed
			* (
				1
				- math.min(
					self.Velocity.Magnitude / (Units.Velocity_mdivs / 3.6) / self.Tune.SteerSpeedDecay,
					1 - (self.Tune.MinSteerSpeed / 100)
				)
			)
	end

	UserInputService.MouseBehavior = self.MouseSteerOn and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
	if self.MouseSteerOn then
		local sensivity = SettingsController:GetSetting("MSteerSensivity")
		local delta = UserInputService:GetMouseDelta()
		local x = math.clamp(self.MousePosition.X + delta.X / mouse.ViewSizeX * sensivity * 4, 0, 1)
		local y = 1 - SettingsController:GetSetting("MSteerCursorY")
		self.MousePosition = Vector2.new(x, y)

		local mdZone = SettingsController:GetSetting("MSteerDZone")
		local mST = (self.MousePosition.X - 0.5) / SettingsController:GetSetting("MSteerWidth") * 2
		if math.abs(mST) <= mdZone then
			self.SteerT = 0
		else
			self.SteerT = (math.max(math.min((math.abs(mST) - mdZone), (1 - mdZone)), 0) / (1 - mdZone))
					^ self.Tune.MSteerExp
				* (mST / math.abs(mST))
		end
	end

	--Interpolate Steering
	local CSAmt = 0
	if
		math.abs(self.SteerT) < self.Tune.CSSteerThresh / 100
		and self.CS
		and self.Velocity.Magnitude * (Units.Length_mm / 1000) * 3.6 > self.Tune.CSSpeedThresh
	then
		CSAmt = (
			self.Center:VectorToObjectSpace(self.Velocity):Dot(Vector3.new(1, 0, 0))
			/ math.max(self.Velocity.Magnitude * (Units.Length_mm / 1000) * 3.6, self.Tune.CSSpeedThresh)
		) * (self.Tune.CSAmt / 100)
	else
		CSAmt = 0
	end
	if math.abs(CSAmt) > (self.Tune.CSAmt / 100) * 0.01 then
		self.CSActive = true
	else
		self.CSActive = false
	end
	local SteerWithCounter = math.clamp(self.SteerT + CSAmt, -1, 1)
	local SteerSmoothing =
		math.clamp(math.abs(SteerWithCounter - self.SteerC) ^ (1 / math.max(self.Tune.SteerSmoothing, 0.001)), 0, 1)
	if self.SteerC < SteerWithCounter then
		if self.SteerC < 0 then
			self.SteerC = math.min(SteerWithCounter, self.SteerC + (ReturnSpeed * SteerSmoothing * deltaTime))
		else
			self.SteerC = math.min(SteerWithCounter, self.SteerC + (SteerSpeed * SteerSmoothing * deltaTime))
		end
	else
		if self.SteerC > 0 then
			self.SteerC = math.max(SteerWithCounter, self.SteerC - (ReturnSpeed * SteerSmoothing * deltaTime))
		else
			self.SteerC = math.max(SteerWithCounter, self.SteerC - (SteerSpeed * SteerSmoothing * deltaTime))
		end
	end

	--Steer Decay Multiplier
	local sDecay = (
		1
		- math.min(
			self.Velocity.Magnitude
				/ (Units.Velocity_mdivs / 3.6)
				/ (self.Tune.SteerDecay / (Units.Velocity_mdivs / 3.6)),
			1 - (self.Tune.MinSteer / 100)
		)
	)
	local rsDecay = (
		1
		- math.min(
			self.Velocity.Magnitude
				/ (Units.Velocity_mdivs / 3.6)
				/ (self.Tune.RSteerDecay / (Units.Velocity_mdivs / 3.6)),
			1 - (self.Tune.MinSteer / 100)
		)
	)

	--Apply Steering
	for _, wheel in self.Wheels :: { VehicleTypes.ClientWheel } do
		if wheel.CanSteer == 0 then continue end

		local angle = 0
		local rsteerVariableAngle = 1
		if wheel.CanSteer == 2 then
			if wheel.Instance.Name == "FL" then
				-- self.SteerInner and self.SteerOuter
				angle = (self.SteerC < 0 and self.Tune.SteerInner or self.Tune.SteerOuter) * sDecay
			elseif wheel.Instance.Name == "FR" then
				angle = (self.SteerC < 0 and self.Tune.SteerOuter or self.Tune.SteerInner) * sDecay
			elseif wheel.Instance.Name == "F" then
				angle = self.Tune.SteerInner * sDecay
			elseif wheel.Instance.Name == "RL" then
				angle = (self.SteerC < 0 and self.Tune.RSteerInner or self.Tune.RSteerOuter) * rsDecay
			elseif wheel.Instance.Name == "RR" then
				angle = (self.SteerC < 0 and self.Tune.RSteerOuter or self.Tune.RSteerInner) * rsDecay
			elseif wheel.Instance.Name == "R" then
				angle = self.Tune.RSteerInner * rsDecay
			end
			if not wheel.IsFront then
				if self.Tune.FWSteer == "Static" then
					rsteerVariableAngle = -math.max(0, 1 - (self.Velocity.Magnitude / self.Tune.RSteerSpeed))
				elseif self.Tune.FWSteer == "Speed" then
					rsteerVariableAngle = math.min(1, (self.Velocity.Magnitude / self.Tune.RSteerSpeed))
				elseif self.Tune.FWSteer == "Both" then
					rsteerVariableAngle = -math.max(-1, 1 - (self.Velocity.Magnitude / self.Tune.RSteerSpeed))
				end
			end
		end

		if self.Tune.PowerSteeringType == "New" then
			wheel.Instance.Arm.SteerAttach0.Orientation =
				Vector3.new(0, wheel.CanSteer == 1 and 0 or self.SteerC * angle * rsteerVariableAngle, 0)
		else
			wheel.Instance.Arm.Steer.CFrame = wheel.Instance.Base.CFrame
				* (
					wheel.CanSteer == 1 and CFrame.new(0, 0, 0)
					or (CFrame.Angles(0, -math.rad(self.SteerC * angle * rsteerVariableAngle), 0))
				)
		end
	end
end
