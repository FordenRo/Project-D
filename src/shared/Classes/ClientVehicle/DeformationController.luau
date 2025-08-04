local AssetService = game:GetService("AssetService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local CreateEditableMesh = require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local Types = require(ReplicatedStorage.Shared.Vehicle.Types)
local HittableService = require(ReplicatedStorage.Shared.Services.HittableService)

local player = Players.LocalPlayer

local DeformationController = {}
DeformationController.__index = DeformationController

type DeformationController = Types.DeformationController

function setImageAlpha(image: EditableImage, alpha: number)
	local imageBuffer = image:ReadPixelsBuffer(Vector2.zero, image.Size)
	for i = 1, image.Size.X * image.Size.Y do
		local pixelIndex = (i - 1) * 4
		local a = buffer.readu8(imageBuffer, pixelIndex + 3)
		buffer.writeu8(imageBuffer, pixelIndex + 3, math.floor(a * alpha))
	end
	image:WritePixelsBuffer(Vector2.zero, image.Size, imageBuffer)
end

function whiteToAlpha(image: EditableImage)
	local imageBuffer = image:ReadPixelsBuffer(Vector2.zero, image.Size)
	for i = 1, image.Size.X * image.Size.Y do
		local pixelIndex = (i - 1) * 4
		local r = buffer.readu8(imageBuffer, pixelIndex)
		buffer.writeu8(imageBuffer, pixelIndex + 3, -r)
	end
	image:WritePixelsBuffer(Vector2.zero, image.Size, imageBuffer)
end

function copyImage(image: EditableImage): EditableImage
	return AssetService:CreateEditableImageAsync(Content.fromObject(image))
end

function DeformationController.new(Vehicle: Types.ClientVehicle)
	local self: DeformationController = setmetatable({}, DeformationController) :: any

	self.Vehicle = Vehicle

	self.DeformModel = (self.Vehicle.Instance.Body :: any).Deform
	self.ColliderModel = (self.Vehicle.Instance.Body :: any).Collider
	self.Body = self.DeformModel.Body
	self.BodyTexture = AssetService:CreateEditableImageAsync(self.Body.TextureContent)
	self.BodyMesh = CreateEditableMesh(self.Body)
	self.Body.TextureContent = Content.fromObject(self.BodyTexture)
	self.ScratchTexture = AssetService:CreateEditableImageAsync("rbxassetid://107123302684595")

	local touchedPoints = {}
	local touchedParts = {}
	for _, part in self.ColliderModel:GetChildren() do
		if not part:IsA("BasePart") then continue end

		part.Touched:Connect(function(hitPart)
			if hitPart:IsDescendantOf(self.Vehicle.Instance) then return end
			if hitPart:IsDescendantOf(player.Character) then return end

			table.insert(touchedPoints, part.Position)
			table.insert(touchedParts, hitPart)
		end)
	end

	local canDeform = true
	local meshScale = self.BodyMesh:GetSize() / self.Body.Size
	RunService.PostSimulation:Connect(function()
		if #touchedPoints == 0 then return end

		local points = table.clone(touchedPoints)
		local parts = table.clone(touchedParts)
		table.clear(touchedPoints)
		table.clear(touchedParts)

		local hitVelocity = self.Vehicle.Instance.Body["#Weight"].AssemblyLinearVelocity - self.Vehicle.Velocity
		local force = hitVelocity.Magnitude
		if force < 1 then return end

		local hitCenter = Vector3.new()
		for _, point in points do
			hitCenter += point
		end
		hitCenter /= #points

		HittableService:Hit(parts, hitCenter, hitVelocity / #parts)

		repeat
			task.wait()
		until canDeform

		canDeform = false
		hitCenter = self.Body.CFrame:PointToObjectSpace(hitCenter) * meshScale
		local direction = hitVelocity.Unit
		local relativeDirection = self.Body.CFrame:VectorToObjectSpace(direction)

		local scratch = copyImage(self.ScratchTexture)
		setImageAlpha(scratch, math.clamp(force / 150 ^ 0.7, 0, 1))

		local size = Vector3.one * 5
		local projection = {
			Position = hitCenter,
			Direction = relativeDirection,
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
		self.BodyTexture:DrawImageProjected(self.BodyMesh, projection, config)
		print(string.format("Impact %.1f", force))

		if force > 10 then
			local hitVertexId = self.BodyMesh:FindClosestVertex(hitCenter)
			local hitPosition = self.BodyMesh:GetPosition(hitVertexId)
			local vertices = self.BodyMesh:FindVerticesWithinSphere(hitPosition, 3)
			for k, vertexId in vertices do
				local vertexPosition = self.BodyMesh:GetPosition(vertexId)
				local distance = (hitPosition - vertexPosition).Magnitude
				local distanceMul = (3 - distance) / 3 ^ 2
				local offset = relativeDirection * force / 40 ^ 0.7 * distanceMul
				offset += offset * math.random() * 0.1
				self.BodyMesh:SetPosition(vertexId, vertexPosition + offset)
				if k % 2 == 0 then task.wait() end
			end
		end

		canDeform = true
	end)

	return self
end

function DeformationController.BlowEngine(self: DeformationController)
	local meshScale = self.BodyMesh:GetSize() / self.Body.Size
	local position = self.DeformModel.EngineBlow.Position
	position = self.Body.CFrame:PointToObjectSpace(position) * meshScale
	local radius = self.DeformModel.EngineBlow.Size.X / 2 * meshScale.Magnitude

	task.spawn(function()
		local vertices = self.BodyMesh:FindVerticesWithinSphere(position, radius)
		for k, vertexId in vertices do
			local vertexPosition = self.BodyMesh:GetPosition(vertexId)
			local direction = position - vertexPosition
			local distance = (position - vertexPosition).Magnitude
			local distanceMul = (radius - distance) / radius ^ 0.5
			local offset = direction
				* math.noise(vertexPosition.X, vertexPosition.Y, vertexPosition.Z)
				* distanceMul
				* 0.05
			self.BodyMesh:SetPosition(vertexId, vertexPosition + offset)
			if k % 2 == 0 then task.wait() end
		end
	end)

	local noiseTexture = AssetService:CreateEditableImageAsync("rbxassetid://118989734106899")
	whiteToAlpha(noiseTexture)
	setImageAlpha(noiseTexture, 0.5)

	local projection = {
		Position = position,
		Direction = Vector3.xAxis,
		Size = Vector3.new(5, 0.5, 1) * radius * 2,
		Up = Vector3.yAxis,
	}
	local config = {
		AlphaBlendType = Enum.ImageAlphaType.Default,
		ColorBlendType = Enum.ImageCombineType.AlphaBlend,
		Decal = noiseTexture,
		FadeAngle = 0,
		BlendIntensity = 0,
	}
	self.BodyTexture:DrawImageProjected(self.BodyMesh, projection, config)
end

return DeformationController
