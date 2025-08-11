local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

return function(self: VehicleTypes.ClientVehicle, input: InputObject)
	if not UserInputService:GetFocusedTextBox() then
		--Shift Down [Manual Transmission]
		if
			(
				input.KeyCode == self.Controls.ContlrShiftDown
				or (self.MouseSteerOn and input.KeyCode == self.Controls.MouseShiftDown)
				or ((not self.MouseSteerOn) and input.KeyCode == self.Controls.ShiftDown)
			)
			and ((self.IsOn and ((self.TransmissionMode == "Auto" and self.Gear <= 1) and self.Tune.AutoShiftVers == "New") or self.TransmissionMode == "Semi") or self.TransmissionMode == "Manual")
			and input.UserInputState == Enum.UserInputState.Begin
		then
			if not self._ShiftDown then self._ShiftDown = true end

		--Shift Up [Manual Transmission]
		elseif
			(
				input.KeyCode == self.Controls.ContlrShiftUp
				or (self.MouseSteerOn and input.KeyCode == self.Controls.MouseShiftUp)
				or ((not self.MouseSteerOn) and input.KeyCode == self.Controls.ShiftUp)
			)
			and ((self.IsOn and ((self.TransmissionMode == "Auto" and self.Gear < 1) and self.Tune.AutoShiftVers == "New") or self.TransmissionMode == "Semi") or self.TransmissionMode == "Manual")
			and input.UserInputState == Enum.UserInputState.Begin
		then
			if not self._ShiftUp then self._ShiftUp = true end

		--Toggle Clutch
		elseif
			(
				input.KeyCode == self.Controls.ContlrClutch
				or (self.MouseSteerOn and input.KeyCode == self.Controls.MouseClutch)
				or ((not self.MouseSteerOn) and input.KeyCode == self.Controls.Clutch)
			) and self.TransmissionMode == "Manual"
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self._ClutchPressing = true
				self._InputClutch = true
			elseif input.UserInputState == Enum.UserInputState.End then
				self._ClutchPressing = false
				self._InputClutch = false
			end

		--Toggle PBrake
		elseif
			input.KeyCode == self.Controls.ContlrPBrake
			or (self.MouseSteerOn and input.KeyCode == self.Controls.MousePBrake)
			or ((not self.MouseSteerOn) and input.KeyCode == self.Controls.PBrake)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.PBrake = not self.PBrake
			elseif input.UserInputState == Enum.UserInputState.End then
				if self.Velocity.Magnitude > 5 then self.PBrake = false end
			end

		--Toggle Transmission Mode
		elseif
			(input.KeyCode == self.Controls.ContlrToggleTMode or input.KeyCode == self.Controls.ToggleTransMode)
			and input.UserInputState == Enum.UserInputState.Begin
		then
			local n = 1
			for i, v in self.Tune.TransModes do
				if v == self.TransmissionMode then
					n = i
					break
				end
			end
			n = n + 1
			if n > #self.Tune.TransModes then n = 1 end
			self.TransmissionMode = self.Tune.TransModes[n]

		--Throttle
		elseif
			(
				not self.MouseSteerOn
				and (input.KeyCode == self.Controls.Throttle or input.KeyCode == self.Controls.Throttle2)
			)
			or (
				(
					(
						(self.Controls.MouseThrottle:IsA("UserInputType"))
						and input.UserInputType == self.Controls.MouseThrottle
					)
					or (self.Controls.MouseThrottle:IsA("KeyCode") and input.KeyCode == self.Controls.MouseThrottle)
				) and self.MouseSteerOn
			)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.InputThrottle = 1
			else
				self.InputThrottle = 0
			end

		--Brake
		elseif
			(not self.MouseSteerOn and (input.KeyCode == self.Controls.Brake or input.KeyCode == self.Controls.Brake2))
			or (
				(
					(
						(self.Controls.MouseBrake:IsA("UserInputType"))
						and input.UserInputType == self.Controls.MouseBrake
					)
					or (self.Controls.MouseBrake:IsA("KeyCode") and input.KeyCode == self.Controls.MouseBrake)
				) and self.MouseSteerOn
			)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.InputBrake = 1
			else
				self.InputBrake = 0
			end

		--Steer Left
		elseif
			not self.MouseSteerOn
			and (input.KeyCode == self.Controls.SteerLeft or input.KeyCode == self.Controls.SteerLeft2)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.SteerT = -1
				self._SteerL = true
			else
				if self._SteerR then
					self.SteerT = 1
				else
					self.SteerT = 0
				end
				self._SteerL = false
			end

		--Steer Right
		elseif
			not self.MouseSteerOn
			and (input.KeyCode == self.Controls.SteerRight or input.KeyCode == self.Controls.SteerRight2)
		then
			if input.UserInputState == Enum.UserInputState.Begin then
				self.SteerT = 1
				self._SteerR = true
			else
				if self._SteerL then
					self.SteerT = -1
				else
					self.SteerT = 0
				end
				self._SteerR = false
			end

		--Toggle Mouse Controls
		elseif input.KeyCode == self.Controls.ToggleMouseDrive then
			if input.UserInputState == Enum.UserInputState.End then
				self.MouseSteerOn = not self.MouseSteerOn
				self.InputThrottle = 0
				self.InputBrake = 0
				self.SteerT = 0
			end

		-- Ignition
		elseif input.KeyCode == self.Controls.Ignition and not self.Broken then
			if self.IsOn and not self.Starting then
				if input.UserInputState == Enum.UserInputState.Begin then self.IsOn = false end
			else
				self.Starting = input.UserInputState == Enum.UserInputState.Begin
			end

		-- Leaving the vehicle
		elseif input.KeyCode == self.Controls.Leave then
			if input.UserInputState == Enum.UserInputState.Begin then
				local humanoid = (player.Character :: Model):FindFirstChildWhichIsA("Humanoid") :: Humanoid
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end

		-- Horn
		elseif input.KeyCode == self.Controls.Horn then
			self.Horning = input.UserInputState == Enum.UserInputState.Begin

		--Toggle TCS and ESC
		elseif
			self.Tune.TCSEnabled
			and self.IsOn
			and (input.KeyCode == self.Controls.ToggleTCS or input.KeyCode == self.Controls.ContlrToggleTCS)
		then
			if input.UserInputState == Enum.UserInputState.End then
				if self.Tune.ESCEnabled then
					if self.TCS and self.ESC then
						self.ESC = false
					elseif self.TCS and not self.ESC then
						self.TCS = false
					elseif not self.TCS and not self.ESC then
						self.TCS = true
						self.ESC = true
					end
				else
					self.TCS = not self.TCS
				end
			end

		--Toggle ABS
		elseif
			self.Tune.ABSEnabled
			and self.IsOn
			and (input.KeyCode == self.Controls.ToggleABS or input.KeyCode == self.Controls.ContlrToggleABS)
		then
			if input.UserInputState == Enum.UserInputState.End then self.ABS = not self.ABS end

		--Toggle CS
		elseif
			self.Tune.CSEnabled
			and self.IsOn
			and (input.KeyCode == self.Controls.ToggleCS or input.KeyCode == self.Controls.ContlrToggleCS)
		then
			if input.UserInputState == Enum.UserInputState.End then self.CS = not self.CS end
		end

		--Variable Controls
		if input.UserInputType and input.UserInputType.Name:find("Gamepad") then
			--Gamepad Steering
			if input.KeyCode == self.Controls.ContlrSteer then
				if input.Position.X >= 0 then
					local cDZone = math.min(0.99, self.Controls.ControlRDZone / 100)
					if math.abs(input.Position.X) > cDZone then
						self.SteerT = (input.Position.X - cDZone) / (1 - cDZone)
					else
						self.SteerT = 0
					end
				else
					local cDZone = math.min(0.99, self.Controls.ControlLDZone / 100)
					if math.abs(input.Position.X) > cDZone then
						self.SteerT = (input.Position.X + cDZone) / (1 - cDZone)
					else
						self.SteerT = 0
					end
				end

			--Gamepad Throttle
			elseif input.KeyCode == self.Controls.ContlrThrottle then
				self.InputThrottle = math.max(0, input.Position.Z)

			--Gamepad Brake
			elseif input.KeyCode == self.Controls.ContlrBrake then
				self.InputBrake = input.Position.Z
			end
		end
	else
		self.InputThrottle = 0
		self.SteerT = 0
		self.InputBrake = 0
	end
end
