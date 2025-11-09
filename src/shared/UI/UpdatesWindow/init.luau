local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local UpdateFrame = require(script.UpdateFrame)
local Window = require(script.Parent.Window)

local UpdatesWindow = {}
Window.Extend(UpdatesWindow)

export type UpdatesWindow = {} & Window.Window

type UpdatesWindowImpl = {} & UpdatesWindow

function UpdatesWindow.new(): UpdatesWindow
	local self: UpdatesWindowImpl =
		Window.new((ReplicatedStorage.UI :: any).UpdatesWindow:Clone()) :: any

	setmetatable(self, UpdatesWindow)

	self:GetTab("Changelog").Activated
		:Once(function() InitializeChangelogTab(self) end)

	self:GetTab("Roadmap").Activated
		:Once(function() InitializeRoadmapTab(self) end)

	return self
end

function InitializeChangelogTab(self: UpdatesWindowImpl)
	local updateFrame = (self.Instance :: any).UpdateFrame
	local content = self:GetTab("Changelog").Content

	for _, v in GameConfig.Changelog do
		local frame = UpdateFrame.new(updateFrame:Clone(), v)
		frame.Instance.Parent = content
	end
end

function InitializeRoadmapTab(self: UpdatesWindowImpl)
	local updateFrame = (self.Instance :: any).UpdateFrame
	local content = self:GetTab("Roadmap").Content

	for _, v in GameConfig.Roadmap do
		local frame = UpdateFrame.new(updateFrame, v)
		frame.Instance.Parent = content
	end
end

function UpdatesWindow.Is(obj: any)
	return typeof(obj) == "table" and getmetatable(obj) == UpdatesWindow
end

function UpdatesWindow.Destroy(self: UpdatesWindowImpl) self.Instance:Destroy() end

return table.freeze({
	new = UpdatesWindow.new,
	Is = UpdatesWindow.Is,
})
