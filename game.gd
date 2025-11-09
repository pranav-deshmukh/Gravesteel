extends Node2D

@onready var upgrade_menu = $UpgradeMenu/UpgradeMenu
@onready var player = $Player
@onready var upgrade_data = preload("res://upgrades.gd").new()
@export var world_size: Vector2 = Vector2(8000, 8000)

var next_upgrade_threshold = 5   # how many coins needed for next upgrade
func is_point_inside_world(point: Vector2) -> bool:
	var half = world_size / 2
	return abs(point.x) <= half.x and abs(point.y) <= half.y

func _ready():
	# connect upgrade chosen signal
	upgrade_menu.connect("upgrade_chosen", Callable(self, "_on_upgrade_chosen"))
	
	# also connect player’s coin updates
	player.connect("coin_collected", Callable(self, "_on_player_coin_collected"))


func spawn_mob():
	%PathFollow2D.progress_ratio = randf()
	var new_mob = preload("res://Mob/mob.tscn").instantiate()
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
		next_upgrade_threshold += 5
		
		# show 3 random upgrades
		upgrade_menu.show_upgrades(upgrade_data.upgrades)

func _on_upgrade_chosen(upgrade):
	print("\n=== APPLYING UPGRADE ===")
	#print("Upgrade type: ", upgrade.type)
	#print("Upgrade value: ", upgrade.value)
	
	# Convert to string to handle StringName (&"type") properly
	var upgrade_type = str(upgrade.type)
	
	match upgrade_type:
		"speed":
			var old_speed = player.move_speed
			player.move_speed *= upgrade.value
			#print("✓ Speed: ", old_speed, " -> ", player.move_speed)
		
		"health":
			var old_health = player.max_health
			player.max_health *= upgrade.value
			player.health = player.max_health
			#print("✓ Max Health: ", old_health, " -> ", player.max_health)
			#print("✓ Current Health set to: ", player.health)
		
		"damage":
			var old_damage = player.damage
			player.damage *= upgrade.value
			#print("✓ Damage: ", old_damage, " -> ", player.damage)
		
		"attack_speed":
			var old_speed = player.attack_speed
			player.attack_speed *= upgrade.value
			#print("✓ Attack Speed: ", old_speed, " -> ", player.attack_speed)
		
		#_:
			#print("❌ ERROR: Unknown upgrade type: '", upgrade_type, "'")
	
	#print("===================\n")
