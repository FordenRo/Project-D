local Placer = require(script.Placer)
local Vector3Range = require(script.Vector3Range)
local toolbar = plugin:CreateToolbar("RayPlacer")
local button = toolbar:CreateButton("RayPlacer", "", "")

local placer: Placer.Placer?

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = (((workspace:FindFirstChild(
	"Mirino Circuit"
) :: Model):FindFirstChild("Physics") :: Folder):FindFirstChild("Ground.obj") :: Model):GetChildren()
rayParams.FilterType = Enum.RaycastFilterType.Include

local params: Placer.PlacerParams = {
	Output = workspace:FindFirstChild("SpawnedTrees") :: Folder,
	Objects = (workspace:FindFirstChild("PlacerObjects") :: Folder):GetChildren() :: any,
	Scale = NumberRange.new(0.8, 1.2),
	RayParams = rayParams,
	Offset = Vector3Range.new(Vector3.new()),
	Rotation = Vector3Range.new(
		Vector3.new(0, -180, 0),
		Vector3.new(0, 180, 0)
	),
}

button.Click:Connect(function()
	if plugin:IsActivated() then
		plugin:Deactivate()
	else
		plugin:Activate(true)
		button:SetActive(true)
		if not placer then placer = Placer.new(plugin, params) end
	end
end)

plugin.Deactivation:Connect(function()
	button:SetActive(false)

	if placer then
		placer:Destroy()
		placer = nil
	end
end)
