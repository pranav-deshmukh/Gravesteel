class_name RicochetDagger
extends Node2D

@export var damage: float = 12.0
@export var attack_speed: float = 1.2
@export var dagger_count: int = 1
@export var dagger_speed: float = 500.0
@export var max_bounces: int = 3
@export var bounce_range: float = 300.0
@export var level: int = 1

var attack_timer: Timer
var player

func _ready():
	attack_timer = Timer.new()
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(_on_timer_timeout)
	add_child(attack_timer)
	attack_timer.start()
	
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if player and is_instance_valid(player):
		global_position = player.global_position

func _on_timer_timeout() -> void:
	attack()

func attack():
	var nearest_enemy = find_nearest_enemy()
	
	if nearest_enemy:
		for i in range(dagger_count):
			throw_dagger(nearest_enemy, i)

func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
	
	var nearest = null
	var min_distance = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest = enemy
	
	return nearest

func throw_dagger(target: Node2D, dagger_index: int = 0):
	const DAGGER = preload("res://Weapons/Projectile_Weapons/Dagger/dagger_projectile.tscn")
	var new_dagger = DAGGER.instantiate()
	
	var direction = (target.global_position - global_position).normalized()
	
	if dagger_count > 1:
		var spread_angle = (dagger_index - (dagger_count - 1) / 2.0) * 15.0
		direction = direction.rotated(deg_to_rad(spread_angle))
	
	new_dagger.global_position = global_position
	new_dagger.rotation = direction.angle()
	
	# Set properties
	if "damage" in new_dagger:
		new_dagger.damage = damage
	if "speed" in new_dagger:
		new_dagger.speed = dagger_speed
	if "max_bounces" in new_dagger:
		new_dagger.max_bounces = max_bounces
	if "bounce_range" in new_dagger:
		new_dagger.bounce_range = bounce_range
	if "current_target" in new_dagger:
		new_dagger.current_target = target
	
	get_tree().current_scene.add_child(new_dagger)
	
	if player and player.has_method("shake_camera"):
		player.shake_camera(3)

func upgrade():
	level += 1
	match level:
		2:
			max_bounces = 4
			damage *= 1.2
		3:
			dagger_speed *= 1.3
			damage *= 1.3
		4:
			dagger_count = 2
			max_bounces = 5
		5:
			damage *= 1.5
			bounce_range *= 1.3
		6:
			dagger_count = 3
			max_bounces = 6
		7:
			attack_speed *= 1.5
			attack_timer.wait_time = 1.0 / attack_speed
			damage *= 1.4
		8:
			max_bounces = 8
			damage *= 2.0
			dagger_speed *= 1.5
