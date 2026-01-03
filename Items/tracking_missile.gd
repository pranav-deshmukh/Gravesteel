extends Node2D

var speed: float = 300.0
var turn_speed: float = 3.0
var damage: float = 40.0
var explosion_radius: float = 100.0
var lifetime: float = 5.0
var target_position: Vector2

@onready var trail: Line2D = create_trail()
@onready var particles: CPUParticles2D = create_exhaust()

var velocity: Vector2 = Vector2.ZERO
var age: float = 0.0

func _ready():
	add_child(trail)
	add_child(particles)
	create_missile_visual()
	
	# Initial velocity
	velocity = Vector2.RIGHT.rotated(rotation) * speed

func _physics_process(delta):
	age += delta
	
	if age > lifetime:
		explode()
		return
	
	# Homing behavior
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var target = player.global_position
		var desired_direction = global_position.direction_to(target)
		
		# Smoothly turn toward target
		var current_direction = velocity.normalized()
		var new_direction = current_direction.lerp(desired_direction, turn_speed * delta)
		velocity = new_direction * speed
		
		# Update rotation
		rotation = velocity.angle()
	
	# Move
	global_position += velocity * delta
	
	# Update trail
	update_trail()
	
	# Check for collision with player
	check_collision()

func create_missile_visual():
	# Body
	var body = Polygon2D.new()
	body.polygon = PackedVector2Array([
		Vector2(-10, -4),
		Vector2(15, -2),
		Vector2(15, 2),
		Vector2(-10, 4)
	])
	body.color = Color(0.4, 0.4, 0.5)
	add_child(body)
	
	# Warhead (red tip)
	var warhead = Polygon2D.new()
	warhead.polygon = PackedVector2Array([
		Vector2(15, -2),
		Vector2(20, 0),
		Vector2(15, 2)
	])
	warhead.color = Color(1, 0.2, 0.2)
	add_child(warhead)
	
	# Fins
	for y_offset in [-4, 4]:
		var fin = Polygon2D.new()
		fin.polygon = PackedVector2Array([
			Vector2(-10, y_offset),
			Vector2(-5, y_offset),
			Vector2(-10, y_offset + sign(y_offset) * 6)
		])
		fin.color = Color(0.3, 0.3, 0.4)
		add_child(fin)

func create_trail() -> Line2D:
	var line = Line2D.new()
	line.width = 3
	line.default_color = Color(1, 0.6, 0.3, 0.6)
	return line

func create_exhaust() -> CPUParticles2D:
	var exhaust = CPUParticles2D.new()
	exhaust.emitting = true
	exhaust.amount = 20
	exhaust.lifetime = 0.5
	exhaust.direction = Vector2(-1, 0)
	exhaust.spread = 20
	exhaust.initial_velocity_min = 50
	exhaust.initial_velocity_max = 150
	exhaust.scale_amount_min = 2
	exhaust.scale_amount_max = 5
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.8, 0.3, 1))
	gradient.add_point(0.5, Color(1, 0.4, 0, 0.6))
	gradient.add_point(1.0, Color(0.3, 0.1, 0, 0))
	exhaust.color_ramp = gradient
	
	exhaust.position = Vector2(-10, 0)
	
	return exhaust

func update_trail():
	trail.add_point(Vector2.ZERO)
	if trail.get_point_count() > 30:
		trail.remove_point(0)

func check_collision():
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < 20:  # Hit radius
			explode()

func explode():
	print("Missile exploding!")
	
	# Create explosion
	var explosion = CPUParticles2D.new()
	explosion.global_position = global_position
	explosion.emitting = true
	explosion.one_shot = true
	explosion.amount = 50
	explosion.lifetime = 0.6
	explosion.explosiveness = 0.9
	explosion.spread = 180
	explosion.initial_velocity_min = 150
	explosion.initial_velocity_max = 400
	explosion.scale_amount_min = 5
	explosion.scale_amount_max = 15
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.9, 0.3, 1))
	gradient.add_point(0.5, Color(1, 0.4, 0, 0.8))
	gradient.add_point(1.0, Color(0.3, 0.1, 0, 0))
	explosion.color_ramp = gradient
	
	get_tree().current_scene.add_child(explosion)
	
	# Damage player if in radius
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < explosion_radius:
			var damage_factor = 1.0 - (dist / explosion_radius)
			var actual_damage = damage * damage_factor
			if player.has_method("take_damage"):
				player.take_damage(actual_damage)
	
	# Screen shake
	if player and player.has_method("shake_camera"):
		player.shake_camera(20)
	
	await get_tree().create_timer(0.7).timeout
	if is_instance_valid(explosion):
		explosion.queue_free()
	
	queue_free()
