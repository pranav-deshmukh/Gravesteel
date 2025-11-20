extends Node2D

@onready var upgrade_menu = $UpgradeMenu/UpgradeMenu
@onready var player = $Player
@onready var spawn_timer = $Timer
@onready var upgrade_data = preload("res://upgrades.gd").new()
@onready var wave_label = $WaveLabel/Label
@onready var portal = preload("res://Portal/portal.tscn")

var current_portal = null

@export var world_size: Vector2 = Vector2(8000, 8000)
@export var spawn_distance_min: float = 600.0  # Minimum distance from player
@export var spawn_distance_max: float = 1200.0  # Maximum distance from player

# Level system
var current_level: int = 1
var max_levels: int = 3

# Wave system
var current_wave: int = 0
var waves_per_level: int = 3
var wave_duration: float = 30.0
var wave_timer: float = 0.0
var wave_active: bool = false

# Enemy type weights (higher = more common)
var enemy_spawn_weights = {
	1: {  # Level 1
		"basic": 70,
		"skull": 25,
		"boss1": 3,
		"boss2": 1,
		"boss3": 1
	},
	2: {  # Level 2
		"basic": 50,
		"skull": 35,
		"boss1": 8,
		"boss2": 5,
		"boss3": 2
	},
	3: {  # Level 3
		"basic": 30,
		"skull": 40,
		"boss1": 15,
		"boss2": 10,
		"boss3": 5
	}
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

# Get random spawn position around player
func get_random_spawn_position() -> Vector2:
	var angle = randf() * TAU  # Random angle (0 to 2π)
	var distance = randf_range(spawn_distance_min, spawn_distance_max)
	
	var offset = Vector2(cos(angle), sin(angle)) * distance
	var spawn_pos = player.global_position + offset
	
	# Clamp to world bounds
	var half = world_size / 2
	spawn_pos.x = clamp(spawn_pos.x, -half.x, half.x)
	spawn_pos.y = clamp(spawn_pos.y, -half.y, half.y)
	
	return spawn_pos

# Weighted random selection
func choose_enemy_type() -> String:
	var weights = enemy_spawn_weights[current_level]
	var total_weight = 0
	
	for weight in weights.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var cumulative = 0
	
	for enemy_type in weights.keys():
		cumulative += weights[enemy_type]
		if random_value <= cumulative:
			return enemy_type
	
	return "basic"  # Fallback

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
		"damage":
			player.damage *= upgrade.value
		"attack_speed":
			player.attack_speed *= upgrade.value
