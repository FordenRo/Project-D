local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CreateEditableMesh = require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local HittableService = require(ReplicatedStorage.Shared.Services.HittableService)
local ImageUtils = require(ReplicatedStorage.Shared.Utils.ImageUtils)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local DeformationController = {}
DeformationController.__index = DeformationController

type DeformationController = VehicleTypes.DeformationController

-- Compile scratch textures
local compiledScratchTextures = {}
do
	local taskCount = 0
	local initialImage = AssetService:CreateEditableImageAsync("rbxassetid://107123302684595")
	for i = 1, 10 do
		task.spawn(function()
			local image = ImageUtils.CopyImage(initialImage)
			ImageUtils.SetImageAlpha(image, i / 10)
			compiledScratchTextures[i] = image
			taskCount -= 1
		end)
		taskCount += 1
	end

	repeat
		task.wait()
	until taskCount == 0
	initialImage:Destroy()
end

function DeformationController.new(Vehicle: VehicleTypes.ClientVehicle): DeformationController
	local self: DeformationController = setmetatable({}, DeformationController) :: any

	self.Vehicle = Vehicle

	local collider = self.Vehicle.Instance.Body.Collider
	local colliderMesh = CreateEditableMesh(collider)

	local lastTouch = 0
	local touchingParts = {}
	local touchingPoints = {}
	collider.Touched:Connect(function(touchingPart: BasePart)
		if tick() - lastTouch < 1 / 5 then return end
		if touchingPart:IsDescendantOf(self.Vehicle.Instance) then return end
		if touchingPart:IsDescendantOf(player.Character) then return end
		lastTouch = tick()

		debug.profilebegin("CheckColliding")
		local meshScale = colliderMesh:GetSize() / collider.ExtentsSize
		local directionToPart = (touchingPart.Position - collider.Position).Unit
		for _, vertexId in colliderMesh:GetVertices() do
			local position = colliderMesh:GetPosition(vertexId)
			if directionToPart:Dot(position.Unit) > 0.5 then continue end

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
			if directionToPart:Dot(center.Unit) > 0.5 then continue end

			local worldPosition = collider.CFrame:PointToWorldSpace(center / meshScale)
			for _, part in game.Workspace:GetPartBoundsInRadius(worldPosition, 0.1) do
				if part == touchingPart then table.insert(touchingPoints, worldPosition) end
			end
		end
		table.insert(touchingParts, touchingPart)
		debug.profileend()
	end)

	local lastVelocity = Vector3.zero
	RunService.PreSimulation:Connect(function() lastVelocity = self.Vehicle.WeightPart.AssemblyLinearVelocity end)

	RunService.PostSimulation:Connect(function()
		if #touchingPoints == 0 then return end

		local touchedPoints = table.clone(touchingPoints)
		local touchedParts = table.clone(touchingParts)
		table.clear(touchingPoints)
		table.clear(touchingParts)

		local worldHitVelocity = self.Vehicle.WeightPart.AssemblyLinearVelocity - lastVelocity
		if worldHitVelocity.Magnitude < 1 then return end

		debug.profilebegin("Deformation")
		local worldHitCenter = Vector3.zero
		for _, point in touchedPoints do
			worldHitCenter += point
		end
		worldHitCenter /= #touchedPoints

		HittableService:Hit(touchedParts, worldHitCenter, worldHitVelocity)

		-- Play sound
		local attachment = Instance.new("Attachment")
		attachment.Parent = game.Workspace
		attachment.Position = worldHitCenter

		local sound = ReplicatedStorage.Vehicle.Impact:Clone()
		sound.Ended:Once(function() attachment:Destroy() end)
		sound.Volume = math.clamp(worldHitVelocity.Magnitude / 50, 0, 0.8)
		sound.Distortion.Level = math.clamp(worldHitVelocity.Magnitude / 100, 0.2, 0.9)
		sound.Playing = true
		sound.Parent = attachment

		local hitCenters = {}
		for _, meshPart in self.Vehicle.MeshParts do
			hitCenters[meshPart] = meshPart.CFrame:PointToObjectSpace(worldHitCenter)
		end
		local hitVelocities = {}
		for _, meshPart in self.Vehicle.MeshParts do
			hitVelocities[meshPart] = meshPart.CFrame:VectorToObjectSpace(worldHitVelocity)
		end

		for meshPart, mesh in self.Vehicle.Meshes do
			local meshScale = mesh:GetSize() / meshPart.Size
			local hitCenter = hitCenters[meshPart] * meshScale
			local hitVelocity = hitVelocities[meshPart] * meshScale
			local closestVertexDistance = (
				(mesh:GetPosition(mesh:FindClosestVertex(hitCenter)) - hitCenter) / meshScale
			).Magnitude

			-- Apply scratch texture
			debug.profilebegin("DrawScratch")
			local texture = self.Vehicle.Textures[meshPart]
			if texture and closestVertexDistance < 1 then
				local alpha = math.clamp((worldHitVelocity.Magnitude / 50) ^ 0.7, 0.1, 1)
				local scratch = compiledScratchTextures[math.round(alpha * 10)]

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
			debug.profileend()

			-- Deform
			debug.profilebegin("Deform")
			if worldHitVelocity.Magnitude > 10 and closestVertexDistance < 3 then
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
			debug.profileend()
		end
		debug.profileend()
	end)

	-- Compile dirt textures
	local compiledDirtTextures = {}
	do
		local taskCount = 0
		for meshPart, texture in self.Vehicle.Textures do
			local dirtTextureId = meshPart:GetAttribute("DirtTexture")
			if typeof(dirtTextureId) ~= "string" then continue end

			task.spawn(function()
				local image = AssetService:CreateEditableImageAsync(dirtTextureId)
				ImageUtils.SetImageAlpha(image, 0.05)
				compiledDirtTextures[texture] = image
				taskCount -= 1
			end)
			taskCount += 1
		end

		repeat
			task.wait()
		until taskCount == 0
	end

	-- Dirt update
	task.spawn(function()
		local lastDirt = 0
		while true do
			task.wait(1)
			local dirt = math.floor(self.Vehicle.Dirt ^ 0.7 * 20) / 20
			if dirt - lastDirt > 0.01 then
				debug.profilebegin("DrawDirt")
				for texture, dirtTexture in compiledDirtTextures do
					texture:DrawImage(Vector2.zero, dirtTexture, Enum.ImageCombineType.AlphaBlend)
				end
				debug.profileend()
				lastDirt = dirt
			end
		end
	end)

	return self
end

function DeformationController.BlowEngine(self: DeformationController)
	local deformation = self.Vehicle.Instance.Body.Deformation
	for meshPart, mesh in self.Vehicle.Meshes do
		local meshScale = mesh:GetSize() / meshPart.Size
		local position = deformation.EngineBlow.Position
		position = meshPart.CFrame:PointToObjectSpace(position) * meshScale
		local radius = deformation.EngineBlow.Size.X / 2 * meshScale.Magnitude

		task.spawn(function()
			local vertices = mesh:FindVerticesWithinSphere(position, radius)
			for k, vertexId in vertices do
				local vertexPosition = mesh:GetPosition(vertexId)
				local direction = position - vertexPosition
				local distance = (position - vertexPosition).Magnitude
				local distanceMul = (radius - distance) / radius ^ 0.5
				local offset = direction
					* math.noise(vertexPosition.X, vertexPosition.Y, vertexPosition.Z)
					* distanceMul
					* 0.05
				mesh:SetPosition(vertexId, vertexPosition + offset)
				if k % 2 == 0 then task.wait() end
			end
		end)
	end

	task.spawn(function()
		for meshPart, texture in self.Vehicle.Textures do
			local blowTextureId = meshPart:GetAttribute("EngineBlowTexture")
			if typeof(blowTextureId) ~= "string" then continue end

			local blowTexture = AssetService:CreateEditableImageAsync(Content.fromUri(blowTextureId))
			ImageUtils.SetImageAlpha(blowTexture, 0.3)
			texture:DrawImage(Vector2.zero, blowTexture, Enum.ImageCombineType.AlphaBlend)
			blowTexture:Destroy()
		end
	end)

	-- Show smoke
	for _, smokePart in deformation.BlowSmokeParts:GetChildren() do
		local emitter = smokePart:FindFirstChildOfClass("ParticleEmitter")
		if not emitter then continue end

		emitter.Enabled = true

		local tween = TweenService:Create(emitter, TweenInfo.new(30), { Rate = 0 })
		tween.Completed:Once(function()
			emitter.Enabled = false
			tween:Destroy()
		end)
		task.delay(90, function() tween:Play() end)
	end
end

return DeformationController
