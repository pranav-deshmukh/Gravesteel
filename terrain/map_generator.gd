# res://terrain/map_generator.gd
extends CanvasLayer

var noise = FastNoiseLite.new()
@onready var color_rect = $ColorRect

func generate_map(level: int, map_size: Vector2):
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.01
	noise.seed = level * 1000  # Different seed per level
	
	# Reduce resolution for performance (divide by 8 or 4)
	var size = Vector2i(int(map_size.x / 8), int(map_size.y / 8))
	var image = Image.create(size.x, size.y, false, Image.FORMAT_RGB8)
	
	var terrain_config = get_terrain_config(level)
	
	for x in range(size.x):
		for y in range(size.y):
			var noise_value = noise.get_noise_2d(x, y)
			var color = get_terrain_color(noise_value, terrain_config)
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	color_rect.texture = texture
	color_rect.size = map_size
	color_rect.position = -map_size / 2  # Center the map

func get_terrain_config(level: int) -> Array:
	match level:
		1:  # Grasslands - only 2 types
			return [
				{"color": Color(0.4, 0.3, 0.2), "threshold": -1.0},  # Brown dirt
				{"color": Color(0.2, 0.6, 0.2), "threshold": -0.2}   # Green grass
			]
		2:  # Mixed terrain - 3 types
			return [
				{"color": Color(0.3, 0.25, 0.2), "threshold": -1.0},  # Dark brown
				{"color": Color(0.5, 0.4, 0.3), "threshold": -0.3},   # Light brown
				{"color": Color(0.15, 0.5, 0.15), "threshold": 0.2}   # Dark green
			]
		3:  # Volcanic - add lava
			return [
				{"color": Color(0.2, 0.2, 0.2), "threshold": -1.0},   # Dark rock
				{"color": Color(0.4, 0.3, 0.25), "threshold": -0.4},  # Brown rock
				{"color": Color(0.8, 0.3, 0.1), "threshold": 0.2},    # Lava glow
				{"color": Color(1.0, 0.4, 0.0), "threshold": 0.5}     # Bright lava
			]
		_:
			return [{"color": Color(0.2, 0.6, 0.2), "threshold": -1.0}]

func get_terrain_color(noise_value: float, config: Array) -> Color:
	# Find the appropriate terrain based on noise value
	for i in range(config.size() - 1, -1, -1):  # Check from highest threshold down
		if noise_value >= config[i].threshold:
			return config[i].color
	
	return config[0].color  # Fallback
