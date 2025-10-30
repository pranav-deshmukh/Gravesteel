extends Node2D

@onready var upgrade_menu = $UpgradeMenu
@onready var player = $Player
@onready var upgrade_data = preload("res://upgrades.gd").new()
@export var world_size: Vector2 = Vector2(8000, 8000)

var next_upgrade_threshold = 5   # how many coins needed for next upgrade
func is_point_inside_world(point: Vector2) -> bool:
	var half = world_size / 2
	return abs(point.x) <= half.x and abs(point.y) <= half.y

func _ready():
	# connect upgrade chosen signala
	upgrade_menu.connect("upgrade_chosen", Callable(self, "_on_upgrade_chosen"))
	
	# also connect player’s coin updates
	player.connect("coin_collected", Callable(self, "_on_player_coin_collected"))


func spawn_mob():
	%PathFollow2D.progress_ratio = randf()
	var new_mob = preload("res://mob.tscn").instantiate()
	var pos = %PathFollow2D.global_position
	if is_point_inside_world(pos):
		new_mob.global_position = pos
		add_child(new_mob)


func _on_timer_timeout():
	spawn_mob()


func _on_player_health_depleted():
	%GameOver.show()
	get_tree().paused = true

func _on_player_coin_collected(current_coins):
	if current_coins >= next_upgrade_threshold:
		# reset threshold for next level (optional)d
		#next_upgrade_threshold += 5
		
		# show 3 random upgrades
		upgrade_menu.show_upgrades(upgrade_data.upgrades)

func _on_upgrade_chosen(upgrade):
	match upgrade.type:
		"speed":
			player.move_speed *= upgrade.value
		"health":
			player.max_health *= upgrade.value
			player.health = player.max_health
			print(player.health)
		"damage":
			player.damage *= upgrade.value
		"attack_speed":
			player.attack_speed *= upgrade.value
