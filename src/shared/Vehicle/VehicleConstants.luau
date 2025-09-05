local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local VehicleConstants = {} :: VehicleTypes.VehicleConstants

VehicleConstants.FlipType = "New" -- implement this
VehicleConstants.Haptics = "Controller" -- implement this
VehicleConstants.GravComp = 35
VehicleConstants.WBVisible = false

return VehicleConstants
