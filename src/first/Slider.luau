local RunService = game:GetService("RunService")

local Slider = {}
Slider.__index = Slider

export type Slider = typeof(setmetatable(
	{} :: {
		_conn: RBXScriptConnection,
		_currentProgress: number,
		Instance: Frame & {
			Content: Frame & {
				Fill: Frame,
			},
			Progress: TextLabel,
		},
		Progress: number,
	},
	Slider
))

function Slider.new(instance: Frame)
	local self: Slider = setmetatable({}, Slider) :: any

	self.Instance = instance
	self.Progress = 0
	self._currentProgress = 0

	self._conn = RunService.Heartbeat:Connect(function(deltaTime: number) Update(self, deltaTime) end)

	return self
end

function Slider.SetProgress(self: Slider, value: number) self.Progress = value end

function Update(self: Slider, deltaTime: number)
	self._currentProgress += (self.Progress - self._currentProgress) * deltaTime * 5

	self.Instance.Content.Fill.Size = UDim2.fromScale(self._currentProgress, 1)
	self.Instance.Progress.Text = tostring(math.round(self._currentProgress * 100)) .. "%"
end

function Slider.Destroy(self: Slider) self._conn:Disconnect() end

return Slider
