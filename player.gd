extends CharacterBody2D

signal health_depleted

var health = 100.0
@export var coins = 1

@onready var coin_label = get_node("/root/Game/CoinsCollected/ColorRect/Label")

func _physics_process(delta):
	const SPEED = 600.0
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED

	move_and_slide()
	if direction.x>0:
		%maincharacter.flip_horizontal(false)
	elif direction.x<0:
		%maincharacter.flip_horizontal(true)
		
	if velocity.length() > 0.0:
		%maincharacter.play_walk_animation()
	else:
		%maincharacter.play_idle_animation()
	
	# Taking damage
	const DAMAGE_RATE = 6.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		%HealthBar.value = health
		if health <= 0.0:
			health_depleted.emit()


func add_coins(value):
	coins+=value
	coin_label.text = str(coins) + " coins"
