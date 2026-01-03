extends Node2D

@onready var upgrade_menu = $UpgradeMenu/UpgradeMenu
@onready var player = $Player
@onready var spawn_timer = $Timer
@onready var upgrade_data = preload("res://upgrades.gd").new()
@onready var wave_label = $WaveLabel/Label
@onready var portal = preload("res://Portal/portal.tscn")
@onready var tilemap = $TileMap

var current_portal = null

@export var world_size: Vector2 = Vector2(8000, 8000)
@export var spawn_distance_min: float = 600.0
@export var spawn_distance_max: float = 600.0

# Level system
var current_level: int = 1
var max_levels: int = 3

# Wave system
var current_wave: int = 0
var waves_per_level: int = 3
var wave_duration: float = 30.0
var wave_timer: float = 0.0
var wave_active: bool = false

# ============================================================================
# SPAWN PROGRESSION CONFIG - Easy to edit!
# Format: time_in_seconds: [enemy_types_available]
# ============================================================================
var level_spawn_progression = {
	1: {  # Level 1 - Easy start, gradual difficulty
		0: ["skull", "heavy_mech", "combat_drone"],           # 0-30s: Only skeletons
		30: ["skull", "basic"], # 30-60s: Add orcs
		60: ["skull", "basic", "boss1", "combat_drone"], # 60-90s: Add boss1
		90: ["skull", "basic", "boss1", "boss2"] # 90s+: Add boss2
	},
	2: {  # Level 2 - Faster progression
		0: ["skull"],           # 0-25s: Only skeletons
		25: ["skull", "basic"], # 25-50s: Add orcs
		50: ["skull", "basic", "boss1"], # 50-75s: Add boss1
		75: ["skull", "basic", "boss1", "boss2", "boss3"] # 75s+: Add allwww
	},
	3: {  # Level 3 - Aggressive start
		0: ["skull", "basic"],  # 0-20s: Skeletons + Orcs
		20: ["skull", "basic", "boss1"], # 20-40s: Add boss1
		40: ["skull", "basic", "boss1", "boss2"], # 40-60s: Add boss2
		60: ["skull", "basic", "boss1", "boss2", "boss3"] # 60s+: Everything
	}
}

# Enemy spawn weights (higher = more common in the pool)
var enemy_base_weights = {
	"skull": 50,   # Most common
	"combat_drone":2,
	"heavy_mech":2,
	"basic": 35,   # Common
	"boss1": 10,   # Uncommon
	"boss2": 4,    # Rare
	"boss3": 1     # Very rare
}

# Level configurations
var level_configs = {
	1: {
		"enemy_health_mult": 1.0,
		"enemy_speed_mult": 1.0,
		"spawn_rate": 2.0
	},
	2: {
		"enemy_health_mult": 1.5,
		"enemy_speed_mult": 1.2,
		"spawn_rate": 4
	},
	3: {
		"enemy_health_mult": 2.0,
		"enemy_speed_mult": 1.5,
		"spawn_rate": 5
	}
}

var next_upgrade_threshold = 5

func _ready():
	upgrade_menu.connect("upgrade_chosen", Callable(self, "_on_upgrade_chosen"))
	player.connect("coin_collected", Callable(self, "_on_player_coin_collected"))
	start_level(1)

func _process(delta: float) -> void:
	if wave_active:
		var time_left = int(wave_duration - wave_timer)
		wave_label.text = "Level %d - Wave %d/%d - %ds" % [
			current_level, current_wave, waves_per_level, time_left
		]
	else:
		wave_label.text = "Level %d - Get ready..." % current_level
	
	if wave_active:
		wave_timer += delta
		if wave_timer >= wave_duration:
			end_wave()

func start_level(level_num: int):
	print("=== STARTING LEVEL ", level_num, " ===")
	current_level = level_num
	current_wave = 0
	
	tilemap.generate_terrain(current_level, world_size)

	
	var config = level_configs[current_level]
	spawn_timer.wait_time = 1.0 / config.spawn_rate
	print("Spawn rate: ", config.spawn_rate, " enemies/sec")
	
	start_wave()

func start_wave():
	current_wave += 1
	print("--- Starting wave ", current_wave, "/", waves_per_level, " ---")
	wave_timer = 0.0
	wave_active = true

func end_wave():
	wave_active = false
	print("--- Wave ", current_wave, " complete ---")
	
	if current_wave < waves_per_level:
		print("Next wave in 5 seconds...")
		await get_tree().create_timer(5.0).timeout
		start_wave()
	else:
		print("=== LEVEL ", current_level, " COMPLETE ===")
		spawn_portal()

func spawn_portal():
	print("!!! PORTAL SPAWNING !!!")
	current_portal = portal.instantiate()
	current_portal.global_position = player.global_position + Vector2(200, 0)
	add_child(current_portal)
	current_portal.connect("body_entered", Callable(self, "_on_portal_entered"))
	
func _on_portal_entered(body):
	if body == player and current_portal != null:
		print("Player entered portal!")
		current_portal.queue_free()
		current_portal = null
		next_level()

func next_level():
	if current_level < max_levels:
		start_level(current_level + 1)
	else:
		print("=== VICTORY! ALL LEVELS COMPLETE ===")
		get_tree().paused = true

func is_point_inside_world(point: Vector2) -> bool:
	var half = world_size / 2
	return abs(point.x) <= half.x and abs(point.y) <= half.y

func get_random_spawn_position() -> Vector2:
	var angle = randf() * TAU
	var distance = randf_range(spawn_distance_min, spawn_distance_max)
	
	var offset = Vector2(cos(angle), sin(angle)) * distance
	var spawn_pos = player.global_position + offset
	
	var half = world_size / 2
	spawn_pos.x = clamp(spawn_pos.x, -half.x, half.x)
	spawn_pos.y = clamp(spawn_pos.y, -half.y, half.y)
	
	return spawn_pos

# Get available enemy types based on current time in wave
func get_available_enemy_types() -> Array:
	var progression = level_spawn_progression[current_level]
	var available = []
	
	# Find the highest time threshold we've passed
	var current_time = wave_timer
	var highest_time = 0
	
	for time_key in progression.keys():
		if current_time >= time_key and time_key > highest_time:
			highest_time = time_key
	
	available = progression[highest_time]
	return available

# Weighted random selection from available enemies
func choose_enemy_type() -> String:
	var available = get_available_enemy_types()
	
	if available.is_empty():
		return "skull"  # Fallback
	
	# Calculate total weight for available enemies
	var total_weight = 0
	for enemy_type in available:
		total_weight += enemy_base_weights[enemy_type]
	
	# Pick random based on weight
	var random_value = randf() * total_weight
	var cumulative = 0
	
	for enemy_type in available:
		cumulative += enemy_base_weights[enemy_type]
		if random_value <= cumulative:
			return enemy_type
	
	return available[0]  # Fallback to first available

func spawn_mob():
	var enemy_type = choose_enemy_type()
	var config = level_configs[current_level]
	var spawn_pos = get_random_spawn_position()
	
	if not is_point_inside_world(spawn_pos):
		return
	
	var enemy = null
	
	match enemy_type:
		"basic":
			enemy = preload("res://Mob/mob.tscn").instantiate()
		"skull":
			enemy = preload("res://Mob/skull_enemy.tscn").instantiate()
		"boss1":
			enemy = preload("res://Mob/boss_1.tscn").instantiate()
		"boss2":
			enemy = preload("res://Mob/boss_2.tscn").instantiate()
		"boss3":
			enemy = preload("res://Mob/boss_3.tscn").instantiate()
		"combat_drone":
			enemy = preload("res://Items/combat_drone.tscn").instantiate()
		"heavy_mech":
			enemy = preload("res://Items/heavy_mech.tscn").instantiate()
	
	if enemy:
		# Apply level scaling
		if "health" in enemy:
			enemy.health *= config.enemy_health_mult
		if "speed" in enemy:
			enemy.speed *= config.enemy_speed_mult
		
		enemy.global_position = spawn_pos
		add_child(enemy)

func _on_timer_timeout():
	if wave_active:
		spawn_mob()

func _on_player_health_depleted():
	%GameOver.show()
	get_tree().paused = true

func _on_player_coin_collected(current_coins):
	if current_coins >= next_upgrade_threshold:
		next_upgrade_threshold += 5
		upgrade_menu.show_upgrades(upgrade_data.upgrades)

func _on_upgrade_chosen(upgrade):
	var upgrade_type = str(upgrade.type)
	
	match upgrade_type:
		"speed":
			player.move_speed *= upgrade.value
		"health":
			player.max_health *= upgrade.value
			player.health = player.max_health
			player.update_health_bar()
		"damage":
			player.damage *= upgrade.value
		"attack_speed":
			player.attack_speed *= upgrade.value
