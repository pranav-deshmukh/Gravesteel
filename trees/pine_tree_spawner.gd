extends StaticBody2D
@export var tree_scene: PackedScene

@export var chunk_size: int = 512
@export var trees_per_chunk: int = 10
@export var spawn_radius_chunks: int = 2

@onready var player: CharacterBody2D = get_node("/root/Game/Player")

func _ready() -> void:
	if tree_scene == null:
		print("ERROR: tree_scene is null! Make sure it's assigned in the Inspector.")
		return
	print("My path: ", get_path())
	print("Parent: ", get_parent().name)
	print("Grandparent: ", get_parent().get_parent().name)
var spawned_chunks = {}

func _process(_delta):
	spawn_trees_around_player()

func spawn_trees_around_player():
	var player_chunk = Vector2i(
		int(floor(player.position.x/chunk_size)),
		int(floor(player.position.y/chunk_size))
	)
	for x in range (player_chunk.x-spawn_radius_chunks, player_chunk.x+spawn_radius_chunks+1):
		for y in range(player_chunk.y - spawn_radius_chunks, player_chunk.y + spawn_radius_chunks + 1):
			var chunk_key = Vector2i(x, y)
			if not spawned_chunks.has(chunk_key):
				spawn_chunk(chunk_key)
				spawned_chunks[chunk_key]=true
				
func spawn_chunk(chunk_pos: Vector2i):
	if tree_scene == null:
		print("ERROR: tree_scene is null in spawn_chunk!")
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = int(hash(chunk_pos)) #determinsitic per chunk
	
	for i in range(trees_per_chunk):
		var tree = tree_scene.instantiate()
		var local_x = rng.randf_range(0, chunk_size)
		var local_y = rng.randf_range(0, chunk_size)
		tree.position = Vector2(chunk_pos * chunk_size) + Vector2(local_x, local_y)
		add_child(tree)
