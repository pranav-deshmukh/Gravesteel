extends Area2D

var weapon: Node2D
var direction: Vector2
var distance_traveled: float = 0.0
var returning: bool = false
var throw_position: Vector2
var hit_enemies: Array = []

var trail_points: Array = []
var max_trail_length: int = 15
var spin_speed: float = 20.0

func _ready():
	weapon = get_tree().get_first_node_in_group("player").get_node_or_null("BoomerangBlades")
	
	# Make sure hit_enemies is initialized
	if hit_enemies == null:
		hit_enemies = []

func _physics_process(delta):
	if not weapon:
		queue_free()
		return
	
	var player = get_tree().get_first_node_in_group("player")
	
	if not returning:
		# Moving outward
		var speed = weapon.throw_speed
		position += direction.rotated(rotation) * speed * delta
		distance_traveled += speed * delta
		
		# Start returning at max distance
		if distance_traveled >= weapon.max_distance:
			returning = true
			# Play whoosh sound
			if player and player.has_method("shake_camera"):
				player.shake_camera(2)
	else:
		# Returning to player
		if player and is_instance_valid(player):
			var to_player = (player.global_position - global_position).normalized()
			var speed = weapon.return_speed
			position += to_player * speed * delta
			
			# Face movement direction
			rotation = to_player.angle()
			
			# Check if caught
			if global_position.distance_to(player.global_position) < 30:
				# Caught! Show catch effect
				weapon.create_catch_effect(global_position)
				queue_free()
		else:
			queue_free()
	
	# Spin the blade
	#var visual = get_node_or_null("Visual")a
	
	# Update trail
	update_trail()

func update_trail():
	var trail = get_node_or_null("Trail")
	if not trail:
		return
	
	trail_points.append(global_position)
	
	if trail_points.size() > max_trail_length:
		trail_points.pop_front()
	
	trail.clear_points()
	for point in trail_points:
		trail.add_point(point - global_position)
