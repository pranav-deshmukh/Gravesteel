class_name MeteorShower
extends Node2D

@export var damage: float = 30.0
@export var meteor_count: int = 3  # Meteors per shower
@export var shower_interval: float = 4.0  # Time between showers
@export var impact_radius: float = 60.0
@export var crater_duration: float = 3.0  # Burning crater lasts this long
@export var warning_duration: float = 1.0  # Warning before impact
@export var level: int = 1

var player
var is_showering: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	start_shower_cycle()

func _process(_delta):
	if player and is_instance_valid(player):
		global_position = player.global_position

func start_shower_cycle():
	while true:
		await get_tree().create_timer(shower_interval).timeout
		if not is_showering:
			trigger_meteor_shower()

func trigger_meteor_shower():
	is_showering = true
	
	# Spawn multiple meteors with slight delays
	for i in range(meteor_count):
		spawn_meteor()
		await get_tree().create_timer(0.3).timeout  # Stagger meteors
	
	is_showering = false

func spawn_meteor():
	# Random position around player
	var spawn_offset = Vector2(
		randf_range(-400, 400),
		randf_range(-300, 300)
	)
	var impact_pos = global_position + spawn_offset
	
	# Show warning first
	create_warning_indicator(impact_pos)
	
	# Wait for warning duration
	await get_tree().create_timer(warning_duration).timeout
	
	# Meteor falls
	create_falling_meteor(impact_pos)

func create_warning_indicator(pos: Vector2):
	var warning = Node2D.new()
	warning.global_position = pos
	warning.z_index = -1
	
	# Red circle indicator
	var circle = Polygon2D.new()
	circle.polygon = create_circle_polygon(impact_radius, 32)
	circle.color = Color(1, 0, 0, 0.3)  # Red, transparent
	warning.add_child(circle)
	
	# Pulsing animation
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(circle, "color:a", 0.6, 0.3)
	pulse_tween.tween_property(circle, "color:a", 0.3, 0.3)
	
	# Inner ring
	var inner = Polygon2D.new()
	inner.polygon = create_circle_polygon(impact_radius * 0.5, 24)
	inner.color = Color(1, 0.5, 0, 0.5)  # Orange
	warning.add_child(inner)
	
	# Crosshair lines
	for i in range(4):
		var line = Line2D.new()
		var angle = (PI / 2) * i
		var dir = Vector2(cos(angle), sin(angle))
		line.add_point(dir * impact_radius * 0.3)
		line.add_point(dir * impact_radius * 0.8)
		line.width = 3
		line.default_color = Color(1, 0, 0, 0.8)
		warning.add_child(line)
	
	get_tree().current_scene.add_child(warning)
	
	# Remove after warning duration
	await get_tree().create_timer(warning_duration).timeout
	if is_instance_valid(warning):
		warning.queue_free()

func create_falling_meteor(impact_pos: Vector2):
	var meteor = Node2D.new()
	meteor.name = "Meteor"
	
	# Start high above impact point
	meteor.global_position = impact_pos + Vector2(0, -600)
	
	# Meteor visual (rock with fire trail)
	var meteor_body = create_meteor_visual()
	meteor.add_child(meteor_body)
	
	# Fire trail particles
	var trail = CPUParticles2D.new()
	trail.emitting = true
	trail.amount = 30
	trail.lifetime = 0.8
	trail.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	trail.emission_sphere_radius = 15
	trail.direction = Vector2(0, 1)  # Upward (opposite of fall)
	trail.spread = 30
	trail.gravity = Vector2(0, -50)
	trail.initial_velocity_min = 50
	trail.initial_velocity_max = 100
	trail.scale_amount_min = 3
	trail.scale_amount_max = 6
	
	# Gradient from white to orange to red
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 0.8))  # White-yellow
	gradient.add_point(0.5, Color(1, 0.5, 0))  # Orange
	gradient.add_point(1.0, Color(0.5, 0, 0))  # Dark red
	trail.color_ramp = gradient
	
	meteor.add_child(trail)
	
	get_tree().current_scene.add_child(meteor)
	
	# Animate falling
	var fall_tween = create_tween()
	fall_tween.tween_property(meteor, "global_position", impact_pos, 0.5).set_ease(Tween.EASE_IN)
	fall_tween.tween_callback(func(): meteor_impact(impact_pos, meteor))
	
	# Rotate while falling
	var spin_tween = create_tween()
	spin_tween.tween_property(meteor_body, "rotation", TAU * 2, 0.5)
	
	# Screen shake while falling
	if player and player.has_method("shake_camera"):
		player.shake_camera(2)

func create_meteor_visual() -> Node2D:
	var visual = Node2D.new()
	
	# Jagged rock shape
	var rock = Polygon2D.new()
	var points = PackedVector2Array()
	var size = 25.0
	
	# Create irregular polygon
	for i in range(8):
		var angle = (i / 8.0) * TAU
		var radius = size * randf_range(0.7, 1.0)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	rock.polygon = points
	rock.color = Color(0.3, 0.2, 0.1)  # Dark brown
	visual.add_child(rock)
	
	# Glowing cracks
	var glow = Polygon2D.new()
	glow.polygon = create_circle_polygon(size * 0.6, 16)
	glow.color = Color(1, 0.3, 0, 0.6)  # Orange glow
	visual.add_child(glow)
	
	return visual

func meteor_impact(pos: Vector2, meteor: Node2D):
	# Remove meteor
	if is_instance_valid(meteor):
		meteor.queue_free()
	
	# MASSIVE screen shake
	if player and player.has_method("shake_camera"):
		player.shake_camera(15)
	
	# Impact explosion
	create_impact_explosion(pos)
	
	# Damage enemies in radius
	damage_enemies_in_radius(pos)
	
	# Create burning crater
	create_burning_crater(pos)
	
	# Screen flash
	create_screen_flash()

func create_impact_explosion(pos: Vector2):
	var explosion = Node2D.new()
	explosion.global_position = pos
	
	# Expanding shockwave rings
	for i in range(4):
		var ring = Line2D.new()
		var points = create_circle_polygon(5, 32)
		for point in points:
			ring.add_point(point)
		ring.add_point(points[0])  # Close the circle
		ring.width = 4
		ring.default_color = Color(1, 0.5, 0, 0.8)
		explosion.add_child(ring)
		
		# Expand and fade
		var delay = i * 0.05
		await get_tree().create_timer(delay).timeout
		var tween = create_tween()
		tween.tween_property(ring, "width", 8, 0.3)
		tween.parallel().tween_method(func(val): 
			for j in range(ring.get_point_count()):
				ring.set_point_position(j, ring.get_point_position(j).normalized() * val)
		, 5.0, impact_radius * 1.5, 0.4)
		tween.parallel().tween_property(ring, "default_color:a", 0.0, 0.4)
	
	# Explosion particles
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 50
	particles.lifetime = 1.0
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 10
	particles.spread = 180
	particles.gravity = Vector2(0, 200)
	particles.initial_velocity_min = 150
	particles.initial_velocity_max = 300
	particles.scale_amount_min = 3
	particles.scale_amount_max = 8
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 0.5))
	gradient.add_point(0.3, Color(1, 0.5, 0))
	gradient.add_point(1.0, Color(0.2, 0.2, 0.2))
	particles.color_ramp = gradient
	
	explosion.add_child(particles)
	
	get_tree().current_scene.add_child(explosion)
	
	# Cleanup
	await get_tree().create_timer(1.5).timeout
	if is_instance_valid(explosion):
		explosion.queue_free()

func damage_enemies_in_radius(pos: Vector2):
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var distance = enemy.global_position.distance_to(pos)
		if distance < impact_radius:
			if enemy.has_method("take_damage"):
				# More damage at center, less at edges
				var damage_mult = 1.0 - (distance / impact_radius) * 0.5
				enemy.take_damage(damage * damage_mult)
			
			# Knockback effect
			var knockback_dir = (enemy.global_position - pos).normalized()
			if "velocity" in enemy:
				enemy.velocity = knockback_dir * 200

func create_burning_crater(pos: Vector2):
	var crater = Node2D.new()
	crater.global_position = pos
	crater.z_index = -2
	
	# Scorched earth circle
	var scorch = Polygon2D.new()
	scorch.polygon = create_circle_polygon(impact_radius * 0.8, 32)
	scorch.color = Color(0.2, 0.1, 0, 0.7)  # Dark burnt color
	crater.add_child(scorch)
	
	# Glowing cracks
	for i in range(6):
		var crack = Line2D.new()
		var angle = (i / 6.0) * TAU + randf() * 0.3
		var length = impact_radius * randf_range(0.5, 0.9)
		crack.add_point(Vector2.ZERO)
		crack.add_point(Vector2(cos(angle), sin(angle)) * length)
		crack.width = 3
		crack.default_color = Color(1, 0.3, 0, 0.8)  # Glowing orange
		crater.add_child(crack)
		
		# Pulse glow
		var glow_tween = create_tween().set_loops()
		glow_tween.tween_property(crack, "default_color:a", 0.4, 0.5)
		glow_tween.tween_property(crack, "default_color:a", 0.8, 0.5)
	
	# Fire particles
	var fire = CPUParticles2D.new()
	fire.emitting = true
	fire.amount = 15
	fire.lifetime = 1.0
	fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	fire.emission_sphere_radius = impact_radius * 0.6
	fire.direction = Vector2(0, -1)
	fire.spread = 20
	fire.gravity = Vector2(0, -30)
	fire.initial_velocity_min = 20
	fire.initial_velocity_max = 50
	fire.scale_amount_min = 2
	fire.scale_amount_max = 5
	
	var fire_gradient = Gradient.new()
	fire_gradient.add_point(0.0, Color(1, 0.8, 0))
	fire_gradient.add_point(0.5, Color(1, 0.3, 0))
	fire_gradient.add_point(1.0, Color(0.3, 0, 0, 0))
	fire.color_ramp = fire_gradient
	
	crater.add_child(fire)
	
	# Damage over time in crater
	damage_crater_continuously(crater, pos)
	
	get_tree().current_scene.add_child(crater)
	
	# Fade out and remove
	await get_tree().create_timer(crater_duration).timeout
	if is_instance_valid(crater):
		var fade = create_tween()
		fade.tween_property(crater, "modulate:a", 0.0, 1.0)
		fade.tween_callback(crater.queue_free)

func damage_crater_continuously(crater: Node2D, pos: Vector2):
	var tick_count = int(crater_duration / 0.5)
	
	for i in range(tick_count):
		await get_tree().create_timer(0.5).timeout
		
		if not is_instance_valid(crater):
			break
		
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			
			var distance = enemy.global_position.distance_to(pos)
			if distance < impact_radius * 0.8:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage * 0.1)  # 10% damage per tick

func create_screen_flash():
	# Briefly flash the entire screen
	var flash = ColorRect.new()
	flash.color = Color(1, 0.8, 0.5, 0.3)  # Orange flash
	flash.size = get_viewport().get_visible_rect().size * 2
	flash.position = -flash.size / 2
	flash.z_index = 100
	
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.add_child(flash)
		
		var tween = create_tween()
		tween.tween_property(flash, "color:a", 0.0, 0.2)
		tween.tween_callback(flash.queue_free)

func create_circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon = PackedVector2Array()
	for i in range(points):
		var angle = (i / float(points)) * TAU
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon

func upgrade():
	level += 1
	match level:
		2:
			meteor_count = 4
			damage *= 1.3
		3:
			impact_radius = 75.0
			shower_interval = 3.5
		4:
			meteor_count = 5
			damage *= 1.4
		5:
			crater_duration = 4.0
			impact_radius = 90.0
		6:
			meteor_count = 6
			damage *= 1.5
		7:
			shower_interval = 3.0
			impact_radius = 110.0
		8:
			meteor_count = 8
			damage *= 2.0
			crater_duration = 5.0
