extends Node2D

@onready var upgrade_menu = $UpgradeMenu/UpgradeMenu
@onready var player = $Player
@onready var spawn_timer = $Timer  # Adjust if your timer has different path
@onready var upgrade_data = preload("res://upgrades.gd").new()
@onready var wave_label = $WaveLabel  # Adjust path


@export var world_size: Vector2 = Vector2(8000, 8000)

# Level system
var current_level: int = 1
var max_levels: int = 3

# Wave system
var current_wave: int = 0
var waves_per_level: int = 3
var wave_duration: float = 30.0
var wave_timer: float = 0.0
var wave_active: bool = false

# Level configurations
var level_configs = {
	1: {
		"enemy_health_mult": 1.0,
		"enemy_speed_mult": 1.0,
		"spawn_rate": 1.0
	},
	2: {
		"enemy_health_mult": 1.5,
		"enemy_speed_mult": 1.2,
		"spawn_rate": 1.5
	},
	3: {
		"enemy_health_mult": 2.0,
		"enemy_speed_mult": 1.5,
		"spawn_rate": 2.0
	}
}

var next_upgrade_threshold = 5

func _ready():
	# Connect signals
	upgrade_menu.connect("upgrade_chosen", Callable(self, "_on_upgrade_chosen"))
	player.connect("coin_collected", Callable(self, "_on_player_coin_collected"))
	
	# START LEVEL 1
	start_level(1)

func _process(delta: float) -> void:
	# Update wave UI
	if wave_active:
		var time_left = int(wave_duration - wave_timer)
		wave_label.text = "Level %d - Wave %d/%d - %ds" % [
			current_level, current_wave, waves_per_level, time_left
		]
	else:
		wave_label.text = "Level %d - Get ready..." % current_level
	
	# Wave timer logic (your existing code)
	if wave_active:
		wave_timer += delta
		
		if wave_timer >= wave_duration:
			end_wave()

func start_level(level_num: int):
	print("=== STARTING LEVEL ", level_num, " ===")
	current_level = level_num
	current_wave = 0
	
	# Adjust spawn rate for this level
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
	
	if current_wave < waves_per_level:  # FIXED: was current_level
		print("Next wave in 5 seconds...")
		await get_tree().create_timer(5.0).timeout
		start_wave()
	else:
		print("=== LEVEL ", current_level, " COMPLETE ===")
		spawn_portal()

func spawn_portal():
	print("!!! PORTAL SPAWNING !!!")
	await get_tree().create_timer(3.0).timeout
	next_level()

func next_level():
	if current_level < max_levels:
		start_level(current_level + 1)
	else:
		print("=== VICTORY! ALL LEVELS COMPLETE ===")
		# TODO: Show victory screen
		get_tree().paused = true

func is_point_inside_world(point: Vector2) -> bool:
	var half = world_size / 2
	return abs(point.x) <= half.x and abs(point.y) <= half.y

func spawn_mob():
	%PathFollow2D.progress_ratio = randf()
	
	var new_mob = preload("res://Mob/mob.tscn").instantiate()
	var config = level_configs[current_level]
	
	var pos = %PathFollow2D.global_position
	if is_point_inside_world(pos):
		# Apply level scaling
		new_mob.health *= config.enemy_health_mult
		new_mob.speed *= config.enemy_speed_mult
		
		new_mob.global_position = pos
		add_child(new_mob)

func _on_timer_timeout():
	if wave_active:  # Only spawn during active waves
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
