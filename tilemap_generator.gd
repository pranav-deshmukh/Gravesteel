extends TileMap

var noise = FastNoiseLite.new()

func generate_terrain(level: int, world_size: Vector2):
	clear()
	
	print("=== GENERATING TERRAIN ===")
	print("Level: ", level)
	print("World size: ", world_size)
	world_size=world_size*1.5
	
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.05
	noise.seed = level * 1000
	
	var tile_size = 16
	var scale_factor = 2  # Your TileMap scale
	var visual_tile_size = tile_size * scale_factor  # 64 pixels per tile visually
	
	var tiles_x = int(world_size.x / visual_tile_size)
	var tiles_y = int(world_size.y / visual_tile_size)
	
	print("Generating tiles: ", tiles_x, "x", tiles_y)
	
	var tile_count = 0
	for x in range(-tiles_x / 2, tiles_x / 2):
		for y in range(-tiles_y / 2, tiles_y / 2):
			var noise_value = noise.get_noise_2d(x, y)
			var source_id = get_tile_source_for_level(noise_value, level)
			
			set_cell(0, Vector2i(x, y), source_id, Vector2i(0, 0))
			tile_count += 1
	
	print("Tiles placed: ", tile_count)
	print("Coverage: ", tiles_x * visual_tile_size, "x", tiles_y * visual_tile_size)
	print("=========================")
	
func get_tile_source_for_level(noise_value: float, level: int) -> int:
	match level:
		1:  # Level 1: grass and dirt only
			if noise_value > -0.2:
				return 0  # First tile (grass)
			else:
				return 1  # Second tile (dirt)
		
		2:  # Level 2: More varied
			if noise_value > 0.1:
				return 0  # grass
			else:
				return 1  # dirt
		
		3:  # Level 3: Add third tile type
			if noise_value > 0.4:
				return 2  # Third tile (lava/special)
			elif noise_value > -0.1:
				return 1  # dirt
			else:
				return 0  # grass
		
		_:
			return 0
