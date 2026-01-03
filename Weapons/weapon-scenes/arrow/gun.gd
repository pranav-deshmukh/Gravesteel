class_name Gun
extends Area2D

@export var damage: float = 12.0
@export var attack_cooldown: float = 0.125  # 8 shots per second
@export var bullet_count: int = 1
@export var pierce_count: int = 0
@export var bullet_speed: float = 1200.0
@export var level: int = 6
@export var ammo_type: String = "standard"  # standard, explosive, armor_piercing, incendiary

@onready var attack_timer: Timer = $Timer
@onready var arrow_sound = $Arrow_sound if has_node("Arrow_sound") else null

var player
var muzzle_flash: CPUParticles2D

func _ready():
	print("===== ASSAULT RIFLE READY =====")
	
	# Configure existing timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = false
	if not attack_timer.timeout.is_connected(_on_timer_timeout):
		attack_timer.timeout.connect(_on_timer_timeout)
	attack_timer.start()
	
	# Get player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Create muzzle flash
	muzzle_flash = create_muzzle_flash()
	add_child(muzzle_flash)

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
	
	# Play sound
	if arrow_sound:
		arrow_sound.pitch_scale = randf_range(0.95, 1.05)
		arrow_sound.play()
	
	# Muzzle flash
	if muzzle_flash:
		muzzle_flash.emitting = true
	
	# Position and rotation
	new_bullet.global_position = global_position
	new_bullet.rotation = rotation
	
	# Add slight spread if multiple bullets
	if bullet_count > 1:
		var spread_angle = (bullet_index - (bullet_count - 1) / 2.0) * 8.0
		new_bullet.rotation_degrees += spread_angle + randf_range(-2, 2)
	
	# Apply bullet properties
	if "damage" in new_bullet:
		new_bullet.damage = damage
	if "speed" in new_bullet:
		new_bullet.speed = bullet_speed
	if "pierce_count" in new_bullet:
		new_bullet.pierce_count = pierce_count
	if "ammo_type" in new_bullet:
		new_bullet.ammo_type = ammo_type
		
		# Set color based on ammo type
		match ammo_type:
			"explosive":
				new_bullet.modulate = Color(1, 0.5, 0)
				if "explosion_radius" in new_bullet:
					new_bullet.explosion_radius = 80.0
			"armor_piercing":
				new_bullet.modulate = Color(0.7, 0.7, 1)
			"incendiary":
				new_bullet.modulate = Color(1, 0.3, 0)
				if "burn_duration" in new_bullet:
					new_bullet.burn_duration = 2.0
			"chain_lightning":
				new_bullet.modulate = Color(0, 1, 1)
				if "chain_count" in new_bullet:
					new_bullet.chain_count = 3
	
	get_tree().current_scene.add_child(new_bullet)
	
	# Camera shake on shoot
	if player and player.has_method("shake_camera"):
		var shake = 3.0 + (level * 1.5)
		player.shake_camera(shake)

func create_muzzle_flash() -> CPUParticles2D:
	var flash = CPUParticles2D.new()
	flash.emitting = false
	flash.one_shot = true
	flash.amount = 15
	flash.lifetime = 0.1
	flash.explosiveness = 1.0
	flash.direction = Vector2(1, 0)
	flash.spread = 30
	flash.initial_velocity_min = 200
	flash.initial_velocity_max = 400
	flash.scale_amount_min = 2
	flash.scale_amount_max = 6
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.9, 0.5, 1))
	gradient.add_point(0.5, Color(1, 0.5, 0, 0.8))
	gradient.add_point(1.0, Color(0.3, 0.1, 0, 0))
	flash.color_ramp = gradient
	
	flash.position = Vector2(30, 0)
	
	return flash

func upgrade():
	level += 1
	print("Weapon upgraded to Mk ", level)
	
	match level:
		2:
			damage *= 1.3
			attack_cooldown = 0.1  # Faster fire rate
			attack_timer.wait_time = attack_cooldown
			print("Mk II: +30% damage, faster fire rate")
		3:
			bullet_count = 2
			print("Mk III: 2 bullets per shot")
		4:
			ammo_type = "armor_piercing"
			damage *= 1.2
			pierce_count = 3
			print("Mk IV: Armor-piercing rounds")
		5:
			attack_cooldown = 0.08
			attack_timer.wait_time = attack_cooldown
			bullet_speed *= 1.3
			print("Mk V: Much faster fire rate")
		6:
			bullet_count = 3
			ammo_type = "explosive"
			print("Mk VI: 3 explosive rounds!")
		7:
			damage *= 1.6
			attack_cooldown = 0.06
			attack_timer.wait_time = attack_cooldown
			print("Mk VII: Massive boost")
		8:
			bullet_count = 5
			ammo_type = "chain_lightning"
			damage *= 2.0
			bullet_speed *= 1.5
			print("Mk VIII: OMEGA - 5 chain-lightning rounds!")
