class_name FireAura
extends Area2D  # Changed: Direct Area2D inheritance

# Weapon stats
@export var damage: float = 5.0
@export var level: int = 1

# Cooldown tracking
var hit_cooldowns: Dictionary = {}
var cooldown_ms: int = 500  # 0.5 seconds between hits

# Player reference
var player: CharacterBody2D

func _ready():
	# Get player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Set collision
	collision_mask = 2  # Detect enemies (layer 2)
	
	print("FireAura ready with damage: ", damage)

func _process(delta):
	if player and is_instance_valid(player):
		global_position = player.global_position
	# Clean up dead enemies from dictionary
	for enemy in hit_cooldowns.keys():
		if not is_instance_valid(enemy):
			hit_cooldowns.erase(enemy)
	
	# Get all enemies currently in the aura
	var enemies = get_overlapping_bodies()
	
	for enemy in enemies:
		if enemy.is_in_group("enemies"):
			if can_damage_enemy(enemy):
				damage_enemy(enemy)

func can_damage_enemy(enemy) -> bool:
	# If never hit this enemy, can damage
	if not hit_cooldowns.has(enemy):
		return true
	
	# Check if cooldown expired
	var current_time = Time.get_ticks_msec()
	var last_hit_time = hit_cooldowns[enemy]
	var time_passed = current_time - last_hit_time
	
	return time_passed >= cooldown_ms

func damage_enemy(enemy):
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		hit_cooldowns[enemy] = Time.get_ticks_msec()
		print("Fire aura damaged: ", enemy.name)

func upgrade():
	level += 1
	apply_upgrade()

func apply_upgrade():
	match level:
		2:
			# Increase radius
			if $CollisionShape2D:
				$CollisionShape2D.shape.radius *= 1.3
			print("Fire Aura: +30% radius")
		3:
			# More damage
			damage *= 1.5
			print("Fire Aura: +50% damage")
		4:
			# Faster ticks
			cooldown_ms = 300
			print("Fire Aura: Faster burn")
		5:
			# More damage again
			damage *= 1.5
			print("Fire Aura: +50% damage")
		6:
			# Massive radius and rapid ticks
			if $CollisionShape2D:
				$CollisionShape2D.shape.radius *= 1.5
			cooldown_ms = 200
			print("Fire Aura: Huge aura + rapid ticks")
