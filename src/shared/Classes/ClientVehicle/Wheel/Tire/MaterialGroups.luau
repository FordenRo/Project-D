local groups = {
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
}

return (groups :: any) :: typeof(setmetatable({} :: typeof(groups), {} :: { __iter: (any) -> () -> (string, string) }))

