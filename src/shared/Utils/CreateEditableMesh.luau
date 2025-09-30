--!strict
local AssetService = game:GetService("AssetService")

return function(meshPart: MeshPart, dynamic: boolean?): EditableMesh
	local editableMesh = AssetService:CreateEditableMeshAsync(
		meshPart.MeshContent,
		{ FixedSize = not dynamic }
	)
	local newMeshPart =
		AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh))
	meshPart:ApplyMesh(newMeshPart)
	return editableMesh
end
