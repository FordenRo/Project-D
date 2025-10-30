--!nocheck
local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local CreateEditableMesh =
	require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local HittableService =
	require(ReplicatedStorage.Shared.Services.HittableService)
local ImageUtil = require(ReplicatedStorage.Shared.Utils.ImageUtil)
local MakeUtil = require(ReplicatedStorage.Shared.Utils.MakeUtil)
local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)
local Trove = require(ReplicatedStorage.Shared.Utils.Trove)
local VehicleTypes = require(ReplicatedStorage.Shared.Types.VehicleTypes)

local player = Players.LocalPlayer

local DeformationController = {}
DeformationController.__index = DeformationController

type DeformationController = VehicleTypes.DeformationController

type DeformationControllerImpl = {
	RE: RemoteEvent,
	trove: Trove.Trove,
} & DeformationController

-- Compile scratch textures
local compiledScratchTextures = {}
do
	local taskCount = 0
	local initialImage = AssetService:CreateEditableImageAsync(
		Content.fromUri("rbxassetid://107123302684595")
	)
	compiledScratchTextures[10] = initialImage

	for i = 2, 9 do
		task.spawn(function()
			local image = ImageUtil.CopyImage(initialImage)
			ImageUtil.SetImageAlpha(image, i / 10)
			compiledScratchTextures[i] = image
			taskCount -= 1
		end)
		taskCount += 1
	end

	repeat
		task.wait()
	until taskCount == 0
end

local RemoteAction = {
	Deform = 1,
	Scratch = 2,
}

function DeformationController.new(
	vehicle: VehicleTypes.ClientVehicle
): DeformationController
	local self: DeformationControllerImpl =
		setmetatable({}, DeformationController) :: any

	self.Vehicle = vehicle
	self.RE = self.Vehicle.Instance:WaitForChild("_DeformRE") :: RemoteEvent

	self.trove = Trove.new()

	self.trove:Connect(
		self.RE.OnClientEvent,
		function(...) Replicate(self, ...) end
	)

	InitializeDeformation(self)
	InitializeDirt(self)

	return self
end

function InitializeDeformation(self: DeformationControllerImpl)
	local collider = self.Vehicle.Instance.Body.Collider
	local colliderMesh = CreateEditableMesh(collider)

	local trove: Trove.Trove?

	local function makeConnections()
		trove = Trove.new()
		assert(trove, "Type check")

		local lastTouch = 0
		local touchingParts = {}
		local touchingPoints = {}
		trove:Connect(collider.Touched, function(touchingPart: BasePart)
			if tick() - lastTouch < 1 / 5 then return end
			if touchingPart:IsDescendantOf(self.Vehicle.Instance) then
				return
			end
			if
				player.Character
				and touchingPart:IsDescendantOf(player.Character)
			then
				return
			end
			lastTouch = tick()

			debug.profilebegin("CheckColliding")
			local meshScale = colliderMesh:GetSize() / collider.ExtentsSize

			local positions = TableUtil.Map(
				colliderMesh:GetVertices(),
				function(vertexId: number)
					local position = colliderMesh:GetPosition(vertexId)
					local worldPosition =
						collider.CFrame:PointToWorldSpace(position / meshScale)
					return worldPosition
				end
			)

			local touchingPartPosition = touchingPart.Position
			table.sort(
				positions,
				function(a, b)
					return (a - touchingPartPosition).Magnitude
						< (b - touchingPartPosition).Magnitude
				end
			)

			local found
			for _, position in positions do
				for _, part in
					game.Workspace:GetPartBoundsInRadius(position, 0.2)
				do
					if part == touchingPart then
						table.insert(touchingPoints, position)
						found = true
						break
					end
				end
				if found then break end
			end
			if not found then warn("Collide touching point haven't found") end

			table.insert(touchingParts, touchingPart)
			debug.profileend()
		end)

		local lastVelocity = Vector3.zero
		trove:Connect(
			RunService.PreSimulation,
			function() lastVelocity = self.Vehicle.Velocity end
		)

		trove:Connect(RunService.PostSimulation, function()
			if #touchingPoints == 0 then return end

			local touchedPoints = table.clone(touchingPoints)
			local touchedParts = table.clone(touchingParts)
			table.clear(touchingPoints)
			table.clear(touchingParts)

			local worldHitVelocity = self.Vehicle.Velocity - lastVelocity
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

			local emitter = Instance.new("AudioEmitter")
			emitter.Parent = attachment

			local audioPlayer = Instance.new("AudioPlayer")
			audioPlayer.Asset = "rbxassetid://7836644875"
			audioPlayer.Volume = math.min(worldHitVelocity.Magnitude / 50, 1.5)
			audioPlayer.Ended:Once(function() attachment:Destroy() end)
			audioPlayer.Parent = emitter

			MakeUtil.Wire(audioPlayer, emitter)

			audioPlayer:Play()

			local hitCenters = {}
			for _, meshPart in self.Vehicle.MeshParts do
				hitCenters[meshPart] =
					meshPart.CFrame:PointToObjectSpace(worldHitCenter)
			end
			local hitVelocities = {}
			for _, meshPart in self.Vehicle.MeshParts do
				hitVelocities[meshPart] =
					meshPart.CFrame:VectorToObjectSpace(worldHitVelocity)
			end

			local affectedMeshParts = {}
			for meshPart, mesh in self.Vehicle.Meshes do
				local meshScale = mesh:GetSize() / meshPart.Size
				local hitCenter = hitCenters[meshPart] * meshScale
				local hitVelocity = hitVelocities[meshPart] * meshScale
				local closestVertexDistance = ((mesh:GetPosition(
					mesh:FindClosestVertex(hitCenter)
				) - hitCenter) / meshScale).Magnitude

				-- Apply scratch texture
				debug.profilebegin("DrawScratch")
				local texture = self.Vehicle.Textures[meshPart]
				if texture and closestVertexDistance < 1 then
					local alpha = math.clamp(
						(worldHitVelocity.Magnitude / 50) ^ 0.7,
						0.2,
						1
					)
					local scratchIdx = math.round(alpha * 10)
					local scratch = compiledScratchTextures[scratchIdx]

					local size = meshScale * 2
					local projection = {
						Position = hitCenter,
						Direction = hitVelocity.Unit,
						Size = size,
						Up = Vector3.yAxis,
					}
					DrawScratch(mesh, texture, scratch, projection)
					scratch:Destroy()

					self.RE:FireServer(
						RemoteAction.Scratch,
						table.find(self.Vehicle.MeshParts, meshPart),
						scratchIdx,
						projection
					)
				end
				debug.profileend()

				-- Deform
				debug.profilebegin("Deform")
				if
					worldHitVelocity.Magnitude > 10
					and closestVertexDistance < 3
				then
					local vertices = mesh:FindVerticesWithinSphere(
						hitCenter,
						3 * meshScale.Magnitude
					)
					local affectedVertices = {}
					for k, vertexId in vertices do
						local position = mesh:GetPosition(vertexId)
						local distance = ((hitCenter - position) / meshScale).Magnitude
						if distance > 3 then continue end

						local distanceMul = (3 - distance) / 3 ^ 2
						local offset = hitVelocity.Unit
							* hitVelocity.Magnitude ^ 0.7
							* 0.1
							* distanceMul
						offset += offset * math.random() * 0.1

						mesh:SetPosition(vertexId, position + offset)
						affectedVertices[vertexId] = position + offset
					end
					affectedMeshParts[table.find(
						self.Vehicle.MeshParts,
						meshPart
					)] =
						affectedVertices
				end
				debug.profileend()
			end
			if not TableUtil.IsEmpty(affectedMeshParts) then
				self.RE:FireServer(RemoteAction.Deform, affectedMeshParts)
			end
			debug.profileend()
		end)
	end

	self.trove:Connect(self.Vehicle.DriverChanged, function()
		if self.Vehicle.IsDriven and not trove then
			makeConnections()
		elseif not self.Vehicle.IsDriven and trove then
			trove:Destroy()
			trove = nil
		end
	end)
end

function InitializeDirt(self: DeformationControllerImpl)
	-- Compile dirt textures
	local compiledDirtTextures = {}
	do
		local taskCount = 0
		for meshPart, texture in self.Vehicle.Textures do
			local dirtTextureId = meshPart:GetAttribute("DirtTexture")
			if typeof(dirtTextureId) ~= "string" then continue end

			task.spawn(function()
				local image = AssetService:CreateEditableImageAsync(
					Content.fromUri(dirtTextureId)
				)
				ImageUtil.SetImageAlpha(image, 0.05)
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
	self.trove:Add(task.spawn(function()
		local lastDirt = 0
		while true do
			task.wait(1)
			local dirt = math.floor(self.Vehicle.Dirt ^ 0.7 * 20) / 20
			if dirt - lastDirt > 0.01 then
				debug.profilebegin("DrawDirt")
				for texture, dirtTexture in compiledDirtTextures do
					texture:DrawImage(
						Vector2.zero,
						dirtTexture,
						Enum.ImageCombineType.AlphaBlend
					)
				end
				debug.profileend()
				lastDirt = dirt
			end
		end
	end))
end

function DrawScratch(
	mesh: EditableMesh,
	texture: EditableImage,
	decal: EditableImage,
	projection: { [string]: any }
)
	local config = {
		AlphaBlendType = Enum.ImageAlphaType.Default,
		ColorBlendType = Enum.ImageCombineType.AlphaBlend,
		Decal = decal,
		FadeAngle = 0,
		BlendIntensity = 0,
	}
	texture:DrawImageProjected(mesh, projection, config)
end

function Replicate(self: DeformationControllerImpl, action: number, ...)
	local actions = {} :: any

	actions[RemoteAction.Deform] = function(
		affectedMeshParts: { [number]: { Vector3 } }
	)
		for meshPartIdx, vertices in affectedMeshParts do
			local meshPart = self.Vehicle.MeshParts[meshPartIdx]
			local mesh = self.Vehicle.Meshes[meshPart]
			if not mesh then continue end

			for vertexId, newPosition in vertices do
				mesh:SetPosition(vertexId, newPosition)
			end
		end
	end

	actions[RemoteAction.Scratch] = function(
		meshPartIdx,
		scratchIdx: number,
		projection: { [string]: any }
	)
		local meshPart = self.Vehicle.MeshParts[meshPartIdx]
		local mesh = self.Vehicle.Meshes[meshPart]
		local texture = self.Vehicle.Textures[meshPart]
		if not mesh or not texture then return end

		DrawScratch(
			mesh,
			texture,
			compiledScratchTextures[scratchIdx],
			projection
		)
	end

	actions[action](...)
end

function DeformationController.BlowEngine(self: DeformationControllerImpl)
	task.spawn(function()
		-- Apply texture
		for meshPart, texture in self.Vehicle.Textures do
			local blowTextureId = meshPart:GetAttribute("EngineBlowTexture")
			if typeof(blowTextureId) ~= "string" then continue end

			task.spawn(function()
				local blowTexture = AssetService:CreateEditableImageAsync(
					Content.fromUri(blowTextureId)
				)
				ImageUtil.SetImageAlpha(blowTexture, 0.3)
				texture:DrawImage(
					Vector2.zero,
					blowTexture,
					Enum.ImageCombineType.AlphaBlend
				)
				blowTexture:Destroy()
			end)
		end

		-- Deform
		local deformation = self.Vehicle.Instance.Body.Deformation
		for meshPart, mesh in self.Vehicle.Meshes do
			local meshScale = mesh:GetSize() / meshPart.Size
			local position = deformation.EngineBlow.Position
			position = meshPart.CFrame:PointToObjectSpace(position) * meshScale
			local radius = deformation.EngineBlow.Size.X / 2 * meshScale.Y

			local vertices = mesh:FindVerticesWithinSphere(position, radius)
			for k, vertexId in vertices do
				local vertexPosition = mesh:GetPosition(vertexId)
				local direction = position - vertexPosition
				local distance = (position - vertexPosition).Magnitude
				local distanceMul = (radius - distance) / radius ^ 0.5
				local offset = direction
					* math.noise(
						vertexPosition.X,
						vertexPosition.Y,
						vertexPosition.Z
					)
					* distanceMul
					* 0.05
				mesh:SetPosition(vertexId, vertexPosition + offset)
			end
		end

		-- Show smoke
		for _, smokePart in deformation.BlowSmokeParts:GetChildren() do
			local emitter = smokePart:FindFirstChildOfClass("ParticleEmitter")
			if not emitter then continue end

			emitter.Enabled = true

			local tween =
				TweenService:Create(emitter, TweenInfo.new(30), { Rate = 0 })
			tween.Completed:Once(function() emitter.Enabled = false end)
			task.delay(90, function() tween:Play() end)
		end
	end)
end

return table.freeze({ new = DeformationController.new })
