local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CreateEditableMesh = require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)
local Units = require(ReplicatedStorage.Shared.Utils.Units)

local player = Players.LocalPlayer

local DeformationController = {}
DeformationController.__index = DeformationController

type DeformationController = {
	Vehicle: Types.ClientVehicle,
	Collider: MeshPart,
	ColliderMesh: EditableMesh,
	DeformParts: { MeshPart },
	DeformMeshes: { EditableMesh },
}

function createPoint(position: Vector3, parent: Instance)
	local ball = Instance.new("Part")

	ball.Name = "Ball"
	ball.Size = Vector3.new(0.2, 0.2, 0.2)
	ball.Position = position
	ball.CanCollide = false
	ball.Anchored = false
	ball.Parent = parent

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ball
	weld.Part1 = parent
	weld.Parent = ball

	return ball
end

function DeformationController.new(Vehicle: Types.ClientVehicle)
	local self = setmetatable({}, DeformationController)

	self.Vehicle = Vehicle

	self.Collider = self.Vehicle.Instance.Body.Collider
	self.ColliderMesh = CreateEditableMesh(self.Collider)

	self.DeformParts = {}
	self.DeformMeshes = {}
	self.Points = {}

	for _, part in self.Vehicle.Instance.Body.Deform:GetDescendants() do
		if not part:IsA("MeshPart") then continue end

		table.insert(self.DeformParts, part)
		table.insert(self.DeformMeshes, CreateEditableMesh(part))
		print("Mesh registered")
	end

	-- local touchingParts = {}
	for _, vertex in self.ColliderMesh:GetVertices() do
		local position = self.Collider.CFrame:PointToWorldSpace(self.ColliderMesh:GetPosition(vertex) * 2.3)
		local point = createPoint(position, self.Collider)

		point.Touched:Connect(function(hit)
			if hit:IsDescendantOf(self.Vehicle.Instance) then return end
			-- if table.find(touchingParts, hit) then return end

			-- table.insert(touchingParts, hit)

			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = { hit }
			local rayInfo =
				game.Workspace:Raycast(point.Position, point.Position - self.Collider.CFrame.Position, params)
			if not rayInfo then return end

			local origin = rayInfo.Position
			local normal = rayInfo.Normal
			local force = (point.AssemblyLinearVelocity / Units.Velocity_mdivs):Dot(normal) * self.Vehicle.Tune.Weight

			if force > 1000 then
				print("Impact " .. force)
				for _, mesh in self.DeformMeshes do
					local vertices =
						mesh:FindVerticesWithinSphere(self.Collider.CFrame:PointToObjectSpace(origin), force ^ 0.2)

					for _, vertex in vertices do
						local vertexPosition = mesh:GetPosition(vertex)
						mesh:SetPosition(vertex, vertexPosition - normal * force ^ 0.05)
					end
				end
			end
		end)

		-- point.TouchEnded:Connect(function(hit) table.remove(touchingParts, table.find(touchingParts, hit)) end)

		table.insert(self.Points, point)
	end

	print("DeformationController initialized")

	task.spawn(function()
		while task.wait(1 / 2) do
			self:Update()
		end
	end)

	return self
end

function DeformationController.Update(self: DeformationController) end

return DeformationController
