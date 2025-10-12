--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CreateEditableMesh =
	require(ReplicatedStorage.Shared.Utils.CreateEditableMesh)
local HittableService =
	require(ReplicatedStorage.Shared.Services.HittableService)

local RoadBump = {}
RoadBump.__index = RoadBump

export type RoadBump = {
	Instance: Instance,
}

type RoadBumpImpl = {
	bump: MeshPart,
	legs: { MeshPart },
	meshes: {
		bump: EditableMesh,
		legs: { EditableMesh },
	},
	startVertexPositions: { [number]: Vector3 },
} & RoadBump

function RoadBump.new(instance: Instance): RoadBumpImpl
	local self: RoadBumpImpl = setmetatable({}, RoadBump) :: any

	self.Instance = instance

	self.bump = instance:WaitForChild("Bump") :: any
	-- self.legs = instance:WaitForChild("Legs"):GetChildren()

	self.meshes = {
		bump = CreateEditableMesh(self.bump, true),
		legs = {},
	}

	self.startVertexPositions = {}
	for _, vertex in self.meshes.bump:GetVertices() do
		self.startVertexPositions[vertex] = self.meshes.bump:GetPosition(vertex)
	end

	-- for _, leg in self.legs do
	-- 	table.insert(self.meshes.legs, CreateEditableMesh(leg, true))
	-- end

	HittableService:Register(
		{ self.bump } :: { BasePart },
		function(hit: HittableService.HitResult) OnHit(self, hit) end
	)
	-- HittableService:Register(
	-- 	table.pack(table.unpack(self.legs), self.bump),
	-- 	function(hit: HittableService.HitResult) self:Hit(hit) end
	-- )

	return self
end

function OnHit(self: RoadBumpImpl, hit: HittableService.HitResult)
	local origin = self.meshes.bump:GetPosition(
		self.meshes.bump:FindClosestVertex(
			self.bump.CFrame:PointToObjectSpace(hit.Position)
		)
	)
	local velocity = self.bump.CFrame:VectorToObjectSpace(hit.Velocity)
	local force = velocity.Magnitude

	local vertices =
		self.meshes.bump:FindVerticesWithinSphere(origin, force / 1000)
	for _, vertex in vertices do
		local position = self.meshes.bump:GetPosition(vertex)
		local distance = (position - origin).Magnitude

		local newPosition = position
			+ velocity / 2000 * math.pow(1 - distance / (force / 1000), 2)
		self.meshes.bump:SetPosition(vertex, newPosition)
	end

	for _, face in self.meshes.bump:GetFaces() do
		local faceVertices = self.meshes.bump:GetFaceVertices(face)
		local remove = false
		for _, vertex in faceVertices do
			local startPosition = self.startVertexPositions[vertex]
			local position = self.meshes.bump:GetPosition(vertex)
			local offset = (position - startPosition).Magnitude
			if offset > 3 then
				self.meshes.bump:RemoveFace(face)
				remove = true
				break
			end
		end
		if not remove then
			local color =
				self.meshes.bump:AddColor(Color3.fromRGB(206, 206, 206), 1)
			local recolor = false
			local colors = self.meshes.bump:GetFaceColors(face)
			for k, vertex in faceVertices do
				local startPosition = self.startVertexPositions[vertex]
				local position = self.meshes.bump:GetPosition(vertex)
				local offset = (position - startPosition).Magnitude
				if offset > 0 then
					colors[k] = color
					recolor = true
				end
			end
			if recolor then self.meshes.bump:SetFaceColors(face, colors) end
		end
	end

	-- local legVertices = self.meshes.leg:GetVertices()
	-- for _, vertex in legVertices do
	-- 	local position = self.meshes.leg:GetPosition(vertex)
	-- 	local vertexDirection = (position - origin).Unit
	-- 	local distance = (position - origin).Magnitude
	-- 	if distance > force / 100 then continue end

	-- 	local newPosition = position + vertexDirection * (1 - distance / (force / 100)) * (force / 1000)
	-- 	self.meshes.leg:SetPosition(vertex, newPosition)
	-- end
end

return table.freeze({ new = RoadBump.new })
