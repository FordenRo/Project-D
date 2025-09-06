local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

return function(self: VehicleTypes.ClientVehicle, deltaTime: number)
	-- Apply Steering
	for _, wheel in self.Wheels :: { VehicleTypes.ClientWheel } do
		if wheel.CanSteer == 0 then continue end

		local angle = 0
		local rsteerVariableAngle = 1
		if wheel.CanSteer == 2 then
			if wheel.Instance.Name == "FL" then
				angle = self.Steering < 0 and self.Tune.SteerInner or self.Tune.SteerOuter
			elseif wheel.Instance.Name == "FR" then
				angle = self.Steering < 0 and self.Tune.SteerOuter or self.Tune.SteerInner
			elseif wheel.Instance.Name == "F" then
				angle = self.Tune.SteerInner
			elseif wheel.Instance.Name == "RL" then
				angle = self.Steering < 0 and self.Tune.RSteerInner or self.Tune.RSteerOuter
			elseif wheel.Instance.Name == "RR" then
				angle = self.Steering < 0 and self.Tune.RSteerOuter or self.Tune.RSteerInner
			elseif wheel.Instance.Name == "R" then
				angle = self.Tune.RSteerInner
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
				Vector3.new(0, wheel.CanSteer == 1 and 0 or self.Steering * angle * rsteerVariableAngle, 0)
		else
			wheel.Instance.Arm.Steer.CFrame = wheel.Instance.Base.CFrame
				* (
					wheel.CanSteer == 1 and CFrame.new(0, 0, 0)
					or (CFrame.Angles(0, -math.rad(self.Steering * angle * rsteerVariableAngle), 0))
				)
		end
	end
end
