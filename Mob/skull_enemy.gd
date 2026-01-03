extends CharacterBody2D

signal died

var speed = randf_range(80, 110)
var health: float = 50.0

# Coin drop settings - Easy to edit!
@export var coin_drop_chance: float = 0.3  # 30% chance to drop coin (0.0 = never, 1.0 = always)

@onready var player = get_node("/root/Game/Player")

func _ready():
	add_to_group("enemies")
	%skull.play("walk")

func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()

func take_damage(amount: float = 1.0):
	#%skull.play_hurt()
	health -= amount
	
	if health <= 0:
		die()

func die():
	# Spawn smoke
	var smoke_scene = preload("res://smoke_explosion/smoke_explosion.tscn")
	var smoke = smoke_scene.instantiate()
	get_parent().add_child(smoke)
	smoke.global_position = global_position
	
	# Spawn coin with chance
	if randf() < coin_drop_chance:
		var coin_scene = preload("res://rewards/coins/coin.tscn")
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
	
	player.add_orcs_killed(1)
	died.emit()
	queue_free()
