extends Area2D

var damage: float = 6.0
var speed: float = 850.0
var max_bounces: int = 3
var bounce_range: float = 300.0

var current_bounces: int = 0
var hit_enemies: Array = []
var current_target: Node2D = null
var direction: Vector2 = Vector2.RIGHT

# Trail effect
var trail_points: Array = []
var max_trail_length: int = 20

# Juice variables
var speed_multiplier: float = 1.0
var damage_multiplier: float = 1.0

func _ready():
	body_entered.connect(_on_body_entered)
	
	# Initial direction
	direction = Vector2.RIGHT.rotated(rotation)
	
	# Create trail visual
	create_trail()

func _physics_process(delta):
	# Speed and damage increase with each bounce
	var current_speed = speed * speed_multiplier
	position += direction * current_speed * delta
	rotation = direction.angle()
	
	# Update trail
	update_trail()
	
	# Check if we've lost our target or gone too far
	if current_target and is_instance_valid(current_target):
		var dist = global_position.distance_to(current_target.global_position)
		if dist > bounce_range * 2:
			queue_free()
	else:
		# No target, fly off screen
		if not get_viewport_rect().has_point(global_position):
			queue_free()

func _on_body_entered(body):
	if body.is_in_group("enemies") and body not in hit_enemies:
		# Deal damage
		if body.has_method("take_damage"):
			body.take_damage(damage * damage_multiplier)
		
		hit_enemies.append(body)
		
		# Screen shake increases with bounces
		var shake_amount = 5 + (current_bounces * 2)
		shake_camera(shake_amount)
		
		# Create impact effect
		create_impact_effect(body.global_position)
		
		# Flash enemy white
		flash_enemy(body)
		
		# Check for bounce
		current_bounces += 1
		
		if current_bounces >= max_bounces:
			# Final impact - BIG effect
			create_final_explosion()
			# Slow-mo if we got a lot of bounces
			if current_bounces >= 5:
				trigger_slowmo()
			queue_free()
		else:
			# Find next target
			bounce_to_next_enemy()

func bounce_to_next_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_dist = bounce_range
	
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy not in hit_enemies:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy
	
	if closest_enemy:
		# Increase power with each bounce
		speed_multiplier += 0.2
		damage_multiplier += 0.3
		
		# Update direction
		direction = (closest_enemy.global_position - global_position).normalized()
		current_target = closest_enemy
		
		# Play bounce sound (pitch increases)
		play_bounce_sound()
		
		# Change trail color (gets redder)
		update_trail_color()
	else:
		# No more enemies in range
		queue_free()

func create_trail():
	var line = Line2D.new()
	line.name = "Trail"
	line.width = 3
	line.default_color = Color(1, 0.3, 0.3, 0.8)  # Red
	line.z_index = -1
	add_child(line)

func update_trail():
	var line = get_node_or_null("Trail")
	if not line:
		return
	
	# Add current position
	trail_points.append(global_position)
	
	# Limit trail length
	if trail_points.size() > max_trail_length:
		trail_points.pop_front()
	
	# Update line points (convert to local coordinates)
	line.clear_points()
	for point in trail_points:
		line.add_point(point - global_position)

func update_trail_color():
	var line = get_node_or_null("Trail")
	if not line:
		return
	
	# Gets brighter red with each bounce
	var intensity = min(1.0, 0.3 + (current_bounces * 0.15))
	line.default_color = Color(1, intensity * 0.3, intensity * 0.3, 0.8)
	line.width = 3 + current_bounces

func create_impact_effect(pos: Vector2):
	# Particle effect on hit
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8 + (current_bounces * 2)
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	
	# Red particles
	particles.color = Color(1, 0.2, 0.2)
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 150 + (current_bounces * 20)
	
	get_tree().current_scene.add_child(particles)
	
	# Auto-cleanup
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func create_final_explosion():
	# Big explosion on final hit
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.spread = 180
	
	particles.color = Color(1, 0, 0)
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 300
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	
	get_tree().current_scene.add_child(particles)
	
	await get_tree().create_timer(0.7).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func flash_enemy(enemy: Node2D):
	if not enemy.has_node("Sprite2D"):
		return
	
	var sprite = enemy.get_node("Sprite2D")
	var original_modulate = sprite.modulate
	
	# Flash white
	sprite.modulate = Color(10, 10, 10)
	
	# Return to normal after 0.1s
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(sprite):
		sprite.modulate = original_modulate

func play_bounce_sound():
	# TODO: Add AudioStreamPlayer with increasing pitch
	# pitch = 1.0 + (current_bounces * 0.2)
	pass

func shake_camera(amount: float):
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("shake_camera"):
		player.shake_camera(amount)

func trigger_slowmo():
	# Slow down time briefly
	Engine.time_scale = 0.3
	await get_tree().create_timer(0.2 * Engine.time_scale).timeout
	Engine.time_scale = 1.0
