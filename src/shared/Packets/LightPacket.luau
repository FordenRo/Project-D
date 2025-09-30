--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Serialization = require(ReplicatedStorage.Shared.Utils.Serialization)

return Serialization.Packet({
	State = Serialization.State({ "Off", "Low", "High" }),
	TurnState = Serialization.State({ "Off", "Left", "Right", "Both" }),
})
