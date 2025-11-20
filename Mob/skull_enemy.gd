extends CharacterBody2D

signal died

var speed = randf_range(200, 300)
var health: float = 5.0  # ← Changed to float, increased from 3 to 30

@onready var player = get_node("/root/Game/Player")

func _ready():
	add_to_group("enemies")  # ← ADD THIS! Critical!
	%skull.play("walk")

func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()

# ← UPDATED to accept damage parameter
func take_damage(amount: float = 1.0):
	#%Orcs.play_hurt()
	health -= amount
	
	#print("Enemy took ", amount, " damage. Health left: ", health)  # Debug
	
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
