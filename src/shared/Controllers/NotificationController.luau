local LogService = game:GetService("LogService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NotificationFrame = require(ReplicatedStorage.Shared.UI.NotificationFrame)

local player = Players.LocalPlayer

local NotificationController = {}
NotificationController.__index = NotificationController

local shownNotifications: { NotificationFrame.NotificationFrame } = {}

export type NotificationController = {
	Screen: ScreenGui & { Notification: Frame },

	ShowNotification: (
		self: NotificationController,
		text: string,
		type: Enum.MessageType,
		duration: number?
	) -> (),
}

type NotificationControllerImpl = {} & NotificationController

function NotificationController.new(): NotificationController
	local self: NotificationControllerImpl =
		setmetatable({}, NotificationController) :: any

	self.Screen = (ReplicatedStorage.UI :: any).NotificationScreen:Clone()
	self.Screen.Parent = player.PlayerGui

	LogService.MessageOut:Connect(
		function(text, type) self:ShowNotification(text, type) end
	)

	return self
end

function NotificationController.ShowNotification(
	self: NotificationControllerImpl,
	text: string,
	type: Enum.MessageType,
	duration: number?
)
	local prev = if #shownNotifications > 0
		then shownNotifications[#shownNotifications]
		else nil

	local instance = self.Screen.Notification:Clone()
	instance.Parent = self.Screen

	local notification =
		NotificationFrame.new(instance, text, type, duration, prev)
	table.insert(shownNotifications, notification)
	notification.Destroying:Once(
		function()
			table.remove(
				shownNotifications,
				table.find(shownNotifications, notification)
			)
		end
	)

	if #shownNotifications > 3 then
		assert(table.remove(shownNotifications, 1)):Destroy()
	end
end

return NotificationController.new()
