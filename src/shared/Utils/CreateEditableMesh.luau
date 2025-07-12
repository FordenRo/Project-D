local AssetService = game:GetService("AssetService")

return function(meshPart: MeshPart): EditableMesh
	local editableMesh = AssetService:CreateEditableMeshAsync(meshPart.MeshContent, { FixedSize = false })
	local newMeshPart = AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh))
	meshPart:ApplyMesh(newMeshPart)
	return editableMesh
end
