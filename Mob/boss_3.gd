extends CharacterBody2D

signal died

var speed = randf_range(80, 105)
var health: float = 5.0
@onready var player = get_node("/root/Game/Player")

# Projectile attack variables
var projectile_cooldown = 0.0
var min_fire_interval = 2.0  # Minimum seconds between shots
var max_fire_interval = 5.0  # Maximum seconds between shots
var next_fire_time = 0.0

func _ready():
	add_to_group("enemies")
	%boss3.play("default")
	
	# Set first random fire time
	next_fire_time = randf_range(min_fire_interval, max_fire_interval)

func _physics_process(delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	
	# Handle projectile firing
	projectile_cooldown += delta
	if projectile_cooldown >= next_fire_time:
		fire_projectile()
		projectile_cooldown = 0.0
		# Set next random fire time
		next_fire_time = randf_range(min_fire_interval, max_fire_interval)

func take_damage(amount: float = 1.0):
	health -= amount
	
	if health <= 0:
		die()

func die():
	# Spawn smoke
	var smoke_scene = preload("res://smoke_explosion/smoke_explosion.tscn")
	var smoke = smoke_scene.instantiate()
	get_parent().add_child(smoke)
	smoke.global_position = global_position
	
	# Spawn coin
	var coin_scene = preload("res://rewards/coins/coin.tscn")
	var coin = coin_scene.instantiate()
	get_parent().add_child(coin)
	coin.global_position = global_position
	player.add_orcs_killed(1)
	died.emit()
	queue_free()

func fire_projectile():
	print("Boss firing projectile!")
	$boss3.play("spell_cast")
	await $boss3.animation_finished
	var fireball_scene = preload("res://Projectiles/fireball.tscn")
	var fireball = fireball_scene.instantiate()
	
	# Calculate direction to player
	var direction_to_player = global_position.direction_to(player.global_position)
	
	fireball.global_position = global_position
	fireball.direction = direction_to_player
	fireball.rotation = direction_to_player.angle()
	
	get_parent().add_child(fireball)
	$boss3.play("default")
