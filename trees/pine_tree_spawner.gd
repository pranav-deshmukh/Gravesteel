extends StaticBody2D

@export var tree_scene: PackedScene
@export var chunk_size: int = 512
@export var trees_per_chunk: int = 10
@export var spawn_radius_chunks: int = 2

# 🌍 Define your finite world boundaries
@export var world_size: Vector2 = Vector2(8000, 8000)

@onready var player: CharacterBody2D = get_node("/root/Game/Player")

var spawned_chunks = {}

func _process(_delta):
	spawn_trees_around_player()

func spawn_trees_around_player():
	var player_chunk = Vector2i(
		int(floor(player.position.x / chunk_size)),
		int(floor(player.position.y / chunk_size))
	)

	for x in range(player_chunk.x - spawn_radius_chunks, player_chunk.x + spawn_radius_chunks + 1):
		for y in range(player_chunk.y - spawn_radius_chunks, player_chunk.y + spawn_radius_chunks + 1):
			var chunk_key = Vector2i(x, y)
			var chunk_pos = Vector2(chunk_key) * chunk_size

			# ✅ Only spawn if chunk is inside world bounds
			if not is_chunk_inside_world(chunk_pos):
				continue

			if not spawned_chunks.has(chunk_key):
				spawn_chunk(chunk_key)
				spawned_chunks[chunk_key] = true

func spawn_chunk(chunk_pos: Vector2i):
	if tree_scene == null:
		push_error("ERROR: tree_scene is null in spawn_chunk!")
		return

	var rng = RandomNumberGenerator.new()
	rng.seed = int(hash(chunk_pos)) # deterministic per chunk

	for i in range(trees_per_chunk):
		var tree = tree_scene.instantiate()
		var local_x = rng.randf_range(0, chunk_size)
		var local_y = rng.randf_range(0, chunk_size)
		var world_pos = Vector2(chunk_pos * chunk_size) + Vector2(local_x, local_y)

		# ✅ Only place trees inside finite world
		if is_point_inside_world(world_pos):
			tree.position = world_pos
			add_child(tree)

# 🧭 Check helpers
func is_point_inside_world(point: Vector2) -> bool:
	var half = world_size / 2
	return abs(point.x) <= half.x and abs(point.y) <= half.y

func is_chunk_inside_world(chunk_pos: Vector2) -> bool:
	var half = world_size / 2
	return (
		chunk_pos.x + chunk_size > -half.x and
		chunk_pos.x < half.x and
		chunk_pos.y + chunk_size > -half.y and
		chunk_pos.y < half.y
	)
