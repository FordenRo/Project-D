local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleConstantsType =
	require(ReplicatedStorage.Shared.Types.VehicleTypes.VehicleConstantsType)

local VehicleConstants = {} :: VehicleConstantsType.VehicleConstants

VehicleConstants.FlipType = "New" -- implement this
VehicleConstants.Haptics = "Controller" -- implement this
VehicleConstants.GravComp = 35
VehicleConstants.WBVisible = false

return table.freeze(VehicleConstants) :: VehicleConstantsType.VehicleConstants
