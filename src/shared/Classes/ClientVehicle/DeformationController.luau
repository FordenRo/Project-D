local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CreateEditableMesh = require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local HittableService = require(ReplicatedStorage.Shared.Services.HittableService)
local ImageUtils = require(ReplicatedStorage.Shared.Utils.ImageUtils)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local DeformationController = {}
DeformationController.__index = DeformationController

type DeformationController = VehicleTypes.DeformationController

function DeformationController.new(Vehicle: VehicleTypes.ClientVehicle)
	local self: DeformationController = setmetatable({}, DeformationController) :: any

	self.Vehicle = Vehicle

	local scratchTexture = AssetService:CreateEditableImageAsync("rbxassetid://107123302684595")
	local collider = self.Vehicle.Instance.Body.Collider
	local colliderMesh = CreateEditableMesh(collider)

	local touchingParts = {}
	local touchingPoints = {}
	self.Vehicle.Instance.Body.Collider.Touched:Connect(function(touchingPart: BasePart)
		if touchingPart:IsDescendantOf(self.Vehicle.Instance) then return end
		if touchingPart:IsDescendantOf(player.Character) then return end

		local meshScale = colliderMesh:GetSize() / collider.ExtentsSize
		for _, vertexId in colliderMesh:GetVertices() do
			local position = colliderMesh:GetPosition(vertexId)
			local worldPosition = collider.CFrame:PointToWorldSpace(position / meshScale)
			for _, part in game.Workspace:GetPartBoundsInRadius(worldPosition, 0.1) do
				if part == touchingPart then table.insert(touchingPoints, worldPosition) end
			end
		end
		for _, faceId in colliderMesh:GetFaces() do
			local vertices = colliderMesh:GetFaceVertices(faceId)
			local center = Vector3.zero
			for _, vertexId in vertices do
				center += colliderMesh:GetPosition(vertexId)
			end
			center /= #vertices
			local worldPosition = collider.CFrame:PointToWorldSpace(center / meshScale)
			for _, part in game.Workspace:GetPartBoundsInRadius(worldPosition, 0.1) do
				if part == touchingPart then table.insert(touchingPoints, worldPosition) end
			end
		end
		table.insert(touchingParts, touchingPart)
	end)

	local lastVelocity = Vector3.zero
	RunService.PreSimulation:Connect(function() lastVelocity = self.Vehicle.WeightPart.AssemblyLinearVelocity end)

	local canDeform = true
	RunService.PostSimulation:Connect(function()
		if #touchingPoints == 0 then return end

		local touchedPoints = table.clone(touchingPoints)
		local touchedParts = table.clone(touchingParts)
		table.clear(touchingPoints)
		table.clear(touchingParts)

		local worldHitVelocity = self.Vehicle.WeightPart.AssemblyLinearVelocity - lastVelocity
		if worldHitVelocity.Magnitude < 1 then return end

		local worldHitCenter = Vector3.zero
		for _, point in touchedPoints do
			worldHitCenter += point
		end
		worldHitCenter /= #touchedPoints

		HittableService:Hit(touchedParts, worldHitCenter, worldHitVelocity)

		local hitCenters = {}
		for _, meshPart in self.Vehicle.MeshParts do
			hitCenters[meshPart] = meshPart.CFrame:PointToObjectSpace(worldHitCenter)
		end
		local hitVelocities = {}
		for _, meshPart in self.Vehicle.MeshParts do
			hitVelocities[meshPart] = meshPart.CFrame:VectorToObjectSpace(worldHitVelocity)
		end

		repeat
			task.wait()
		until canDeform
		canDeform = false

		for meshPart, mesh in self.Vehicle.Meshes do
			local meshScale = mesh:GetSize() / meshPart.Size
			local hitCenter = hitCenters[meshPart] * meshScale
			local hitVelocity = hitVelocities[meshPart] * meshScale
			local closestPointDistance = (
				(select(2, mesh:FindClosestPointOnSurface(hitCenter)) :: Vector3 - hitCenter) / meshScale
			).Magnitude

			-- Apply scratch texture
			local texture = self.Vehicle.Textures[meshPart]
			if texture and closestPointDistance < 1 then
				local scratch = ImageUtils.CopyImage(scratchTexture)
				ImageUtils.SetImageAlpha(scratch, math.clamp((worldHitVelocity.Magnitude / 50) ^ 0.7, 0.1, 1))

				local size = meshScale * 2
				local projection = {
					Position = hitCenter,
					Direction = hitVelocity.Unit,
					Size = size,
					Up = Vector3.yAxis,
				}
				local config = {
					AlphaBlendType = Enum.ImageAlphaType.Default,
					ColorBlendType = Enum.ImageCombineType.AlphaBlend,
					Decal = scratch,
					FadeAngle = 0,
					BlendIntensity = 0,
				}
				texture:DrawImageProjected(mesh, projection, config)
				scratch:Destroy()
			end

			task.wait()

			-- Deform
			if worldHitVelocity.Magnitude > 10 and closestPointDistance < 3 then
				local vertices = mesh:FindVerticesWithinSphere(hitCenter, 3 * meshScale.Magnitude)
				for k, vertexId in vertices do
					local position = mesh:GetPosition(vertexId)
					local distance = ((hitCenter - position) / meshScale).Magnitude
					if distance > 3 then continue end

					local distanceMul = (3 - distance) / 3 ^ 2
					local offset = hitVelocity.Unit * hitVelocity.Magnitude ^ 0.7 * 0.1 * distanceMul
					offset += offset * math.random() * 0.1

					mesh:SetPosition(vertexId, position + offset)
				end
			end
			task.wait()
		end
		canDeform = true
	end)

	-- Dirt update
	local affectedTextures = {}
	for meshPart, texture in self.Vehicle.Textures do
		local dirtTextureId = meshPart:GetAttribute("DirtTexture")
		if typeof(dirtTextureId) ~= "string" then continue end

		affectedTextures[texture] = dirtTextureId
	end

	local _lastDirt = 0
	task.spawn(function()
		while true do
			task.wait(1)
			local dirt = math.floor(self.Vehicle.Dirt ^ 0.7 * 20) / 20
			if dirt - _lastDirt > 0.01 then
				for texture, dirtTextureId in affectedTextures do
					local dirtTexture = AssetService:CreateEditableImageAsync(Content.fromUri(dirtTextureId))
					ImageUtils.SetImageAlpha(dirtTexture, dirt - _lastDirt)
					texture:DrawImage(Vector2.zero, dirtTexture, Enum.ImageCombineType.AlphaBlend)
					task.wait(1 / 30)
				end
				_lastDirt = dirt
			end
		end
	end)

	return self
end

return DeformationController
