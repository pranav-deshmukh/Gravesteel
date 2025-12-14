# fireball.gd
extends Area2D

var speed = 300.0
var direction = Vector2.ZERO
var damage = 20.0

var max_distance = 800.0  # Maximum travel distance
var distance_traveled = 0.0

# OR use a timer instead
var lifetime = 3.0  # Seconds before auto-destroy
var time_alive = 0.0

func _ready():
	#collision_layer = 0
	#collision_mask = 1
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta):
	var movement = direction * speed * delta
	position += movement
	
	# Track distance
	distance_traveled += movement.length()
	
	# Destroy if too far
	if distance_traveled >= max_distance:
		queue_free()
		return
	
	# OR use timer instead
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()
		return

func _on_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()

func _on_area_entered(area):
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()
