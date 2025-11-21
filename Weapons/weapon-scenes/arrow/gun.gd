class_name Gun
extends Area2D

@export var damage: float = 10.0
@export var attack_speed: float = 1.0
@export var bullet_count: int = 1
@export var pierce_count: int = 0
@export var bullet_speed: float = 300.0
@export var level: int = 1

var attack_timer: Timer
var player

func _ready():
	# Setup attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = 1.0 / attack_speed
	attack_timer.timeout.connect(_on_timer_timeout)
	add_child(attack_timer)
	attack_timer.start()
	
	# Get player reference
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if player and is_instance_valid(player):
		global_position = player.global_position
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() > 0:
		var target_enemy = enemies_in_range.front()
		look_at(target_enemy.global_position)

func _on_timer_timeout() -> void:
	attack()

func attack():
	var enemies_in_range = get_overlapping_bodies()
	if enemies_in_range.size() > 0:
		for i in range(bullet_count):
			shoot(i)

func shoot(bullet_index: int = 0):
	const BULLET = preload("res://Weapons/weapon-scenes/arrow/bullet_2d.tscn")
	var new_bullet = BULLET.instantiate()
	new_bullet.global_transform = %ShootingPoint.global_transform
	
	# Apply bullet properties
	if new_bullet.has_method("set_damage"):
		new_bullet.set_damage(damage)
	elif "damage" in new_bullet:
		new_bullet.damage = damage
	
	if new_bullet.has_method("set_speed"):
		new_bullet.set_speed(bullet_speed)
	elif "speed" in new_bullet:
		new_bullet.speed = bullet_speed
		
	if new_bullet.has_method("set_pierce"):
		new_bullet.set_pierce(pierce_count)
	elif "pierce_count" in new_bullet:
		new_bullet.pierce_count = pierce_count
	
	# Add slight spread if multiple bullets
	if bullet_count > 1:
		var spread_angle = (bullet_index - (bullet_count - 1) / 2.0) * 15.0
		new_bullet.rotation_degrees += spread_angle
	
	%ShootingPoint.add_child(new_bullet)
	
	# Camera shake on shoot
	if player and player.has_method("shake_camera"):
		player.shake_camera(5)

func upgrade():
	level += 1
	match level:
		2:
			damage *= 1.3
			#print("Gun: +30% damage")
		3:
			attack_speed *= 1.4
			attack_timer.wait_time = 1.0 / attack_speed
			#print("Gun: +40% attack speed")
		4:
			bullet_count = 2
			#print("Gun: 2 bullets per shot")
		5:
			damage *= 1.5
			#print("Gun: +50% damage")
		6:
			bullet_count = 3
			pierce_count = 1
			#print("Gun: 3 bullets, pierce 1 enemy")
		7:
			attack_speed *= 1.5
			attack_timer.wait_time = 1.0 / attack_speed
			#print("Gun: +50% attack speed")
		8:
			damage *= 2.0
			bullet_speed *= 1.5
			#print("Gun: Double damage, faster bullets")
