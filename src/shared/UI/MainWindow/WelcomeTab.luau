local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local WelcomeTab = {}
WelcomeTab.__index = WelcomeTab

export type WelcomeTab = typeof(setmetatable(
	{} :: {
		Instance: Instance & {
			Message: TextLabel,
		},
	},
	WelcomeTab
))

function WelcomeTab.new(instance: ScrollingFrame): WelcomeTab
	local self: WelcomeTab = setmetatable({}, WelcomeTab) :: any

	self.Instance = instance :: any

	local string = ""
	for k, v in GameConfig.Welcome do
		string ..= `{v}\n`
	end
	self.Instance.Message.Text = string

	return self
end

function WelcomeTab.Destroy(self: WelcomeTab) end

return table.freeze({ new = WelcomeTab.new })
