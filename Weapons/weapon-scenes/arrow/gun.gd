class_name Gun
extends Area2D

@export var damage: float = 10.0
@export var attack_cooldown: float = 2.0  # Cooldown in seconds
@export var bullet_count: int = 1
@export var pierce_count: int = 0
@export var bullet_speed: float = 200.0
@export var level: int = 1

@onready var attack_timer: Timer = $Timer  # Reference the existing timer
@onready var arrow_sound = $Arrow_sound
var player

func _ready():
	print("===== GUN _READY CALLED =====")
	# Configure existing timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = false
	if not attack_timer.timeout.is_connected(_on_timer_timeout):
		attack_timer.timeout.connect(_on_timer_timeout)
	attack_timer.start()
	
	print("Gun ready - Cooldown set to: ", attack_cooldown, " seconds")
	print("Timer wait_time is: ", attack_timer.wait_time, " seconds")
	
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
	print("[%s] Gun %s - Timer timeout - attacking!" % [Time.get_ticks_msec() / 1000.0, get_instance_id()])
	attack()

func attack():
	var enemies_in_range = get_overlapping_bodies()
	print("Attack called - Enemies in range: ", enemies_in_range.size())
	if enemies_in_range.size() > 0:
		for i in range(bullet_count):
			shoot(i)

func shoot(bullet_index: int = 0):
	const BULLET = preload("res://Weapons/weapon-scenes/arrow/bullet_2d.tscn")
	var new_bullet = BULLET.instantiate()
	arrow_sound.play()
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
	print("Upgrading to level: ", level)
	match level:
		2:
			damage *= 1.3
			attack_cooldown = 1.5
			print("Gun: +30% damage")
		3:
			attack_cooldown = 1.2  # Reduce by 25% (faster)
			attack_timer.wait_time = attack_cooldown
			print("Gun: Attack cooldown reduced to: ", attack_cooldown, "s")
		4:
			bullet_count = 2
			print("Gun: 2 bullets per shot")
		5:
			damage *= 1.5
			print("Gun: +50% damage")
		6:
			bullet_count = 3
			pierce_count = 1
			print("Gun: 3 bullets, pierce 1 enemy")
		7:
			attack_cooldown *= 1  # Reduce bydd 30% (even faster)
			attack_timer.wait_time = attack_cooldown
			print("Gun: Attack cooldown reduced to: ", attack_cooldown, "s")
		8:
			damage *= 2.0
			bullet_speed *= 1.5
			attack_cooldown *= 0.8  # Reduce by 20%
			attack_timer.wait_time = attack_cooldown
			print("Gun: Double damage, faster bullets, cooldown: ", attack_cooldown, "s")
