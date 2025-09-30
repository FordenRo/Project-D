local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TableUtil = require(ReplicatedStorage.Shared.Utils.TableUtil)

return TableUtil.DeepFreeze({
	Road = {
		"Plastic",
		"Slate",
		"Concrete",
		"Granite",
		"Brick",
		"Pebble",
		"Cobblestone",
		"Rock",
		"Basalt",
		"Ground",
		"Pavement",
		"SmoothPlastic",
		"Asphalt",
	},
	Dirt = {
		"Grass",
		"Mud",
		"Ground",
		"LeafyGrass",
	},
	Sand = {
		"Sand",
		"Sandstone",
		"Limestone",
	},
	Snow = {
		"Glacier",
		"Snow",
	},
})
