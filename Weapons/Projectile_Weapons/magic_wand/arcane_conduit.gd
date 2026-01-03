class_name ArcaneConduit
extends Node2D

@export var damage: float = 10.0
@export var beam_duration: float = 1.5  # How long beam stays visible
@export var cooldown: float = 10.0  # Fire every 5 seconds
@export var beam_width: float = 20.0
@export var max_range: float = 600.0  # Start shorter
@export var level: int = 1

var player
var is_on_cooldown: bool = false
var current_beam = null

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if player and is_instance_valid(player):
		global_position = player.global_position
	
	# Auto-cast when off cooldown
	if not is_on_cooldown:
		cast_beam()

func cast_beam():
	var target = find_nearest_enemy()
	if not target:
		# No target, wait a bit and try again
		await get_tree().create_timer(0.5).timeout
		return
	
	is_on_cooldown = true
	
	# Store target position
	var target_pos = target.global_position
	
	# Create the beam
	current_beam = create_arcane_beam(target_pos)
	add_child(current_beam)
	
	# Charge up effect
	create_charge_effect()
	
	# Deal damage over beam duration
	damage_enemies_in_beam(target_pos)
	
	# Beam stays visible for duration
	await get_tree().create_timer(beam_duration).timeout
	if current_beam:
		fade_out_beam()
	
	# Start 5 second cooldown
	await get_tree().create_timer(cooldown).timeout
	is_on_cooldown = false

func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
	
	var nearest = null
	var min_distance = max_range
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest = enemy
	
	return nearest

func create_arcane_beam(target_pos: Vector2) -> Node2D:
	var beam = Node2D.new()
	beam.name = "ArcaneBeam"
	
	var direction = (target_pos - global_position).normalized()
	var distance = max_range  # ALWAYS use max_range, not distance to target
	
	# Core beam (bright center)
	var core = Line2D.new()
	core.name = "Core"
	core.add_point(Vector2.ZERO)
	core.add_point(direction * distance)
	core.width = beam_width * 0.3
	core.default_color = Color(1, 0.9, 1, 1)  # Bright white-purple
	core.z_index = 2
	beam.add_child(core)
	
	# Middle layer (purple glow)
	var middle = Line2D.new()
	middle.name = "Middle"
	middle.add_point(Vector2.ZERO)
	middle.add_point(direction * distance)
	middle.width = beam_width * 0.6
	middle.default_color = Color(0.8, 0.3, 1, 0.8)  # Purple
	middle.z_index = 1
	beam.add_child(middle)
	
	# Outer glow
	var outer = Line2D.new()
	outer.name = "Outer"
	outer.add_point(Vector2.ZERO)
	outer.add_point(direction * distance)
	outer.width = beam_width
	outer.default_color = Color(0.5, 0, 1, 0.4)  # Dark purple, transparent
	outer.z_index = 0
	beam.add_child(outer)
	
	# Floating runes along the beam
	create_beam_runes(beam, direction, distance)
	
	# Impact effect at end
	create_impact_point(beam, direction * distance)
	
	# Animate beam appearing
	animate_beam_entrance(beam)
	
	# Beam wobble/pulse animation
	animate_beam_pulse(core, middle, outer)
	
	return beam
	
func create_beam_runes(beam: Node2D, direction: Vector2, distance: float):
	# Magical runes that float along the beam
	var rune_count = max(4, int(distance / 50))  # More runes for longer beams
	
	for i in range(rune_count):
		var rune = Node2D.new()
		var progress = (i + 1) / float(rune_count + 1)
		rune.position = direction * distance * progress
		
		# Create rune symbol (mystical polygon)
		var symbol = Polygon2D.new()
		var points = create_rune_shape()
		symbol.polygon = points
		symbol.color = Color(1, 0.8, 1, 0.9)
		symbol.scale = Vector2(0.5, 0.5)
		rune.add_child(symbol)
		
		beam.add_child(rune)
		
		# Spin the runes
		var tween = create_tween().set_loops()
		tween.tween_property(rune, "rotation", TAU, 1.0 + randf() * 0.5)
		
		# Float up and down
		var float_tween = create_tween().set_loops()
		float_tween.tween_property(symbol, "position:y", -5, 0.3)
		float_tween.tween_property(symbol, "position:y", 5, 0.3)

func create_rune_shape() -> PackedVector2Array:
	# Create a star/rune shape
	var points = PackedVector2Array()
	var outer_radius = 8.0
	var inner_radius = 4.0
	var spikes = 6
	
	for i in range(spikes * 2):
		var angle = (i * PI) / spikes
		var radius = outer_radius if i % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	
	return points

func create_impact_point(beam: Node2D, end_pos: Vector2):
	var impact = Node2D.new()
	impact.name = "Impact"
	impact.position = end_pos
	
	# Outer explosion ring
	for ring in range(3):
		var circle = Polygon2D.new()
		circle.polygon = create_circle_polygon(20 + ring * 10, 16)
		circle.color = Color(1, 0.5, 1, 0.3 - ring * 0.1)
		impact.add_child(circle)
		
		# Expand rings
		var tween = create_tween().set_loops()
		tween.tween_property(circle, "scale", Vector2(1.5, 1.5), 0.5)
		tween.tween_property(circle, "scale", Vector2(1.0, 1.0), 0.5)
	
	# Crackling particles
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.explosiveness = 0.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 20
	particles.initial_velocity_max = 60
	particles.color = Color(1, 0.7, 1)
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	impact.add_child(particles)
	
	beam.add_child(impact)

func create_circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon = PackedVector2Array()
	for i in range(points):
		var angle = (i / float(points)) * TAU
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon

func animate_beam_entrance(beam: Node2D):
	# Beam grows from nothing
	beam.scale = Vector2(0, 1)
	var tween = create_tween()
	tween.tween_property(beam, "scale", Vector2(1, 1), 0.2).set_ease(Tween.EASE_OUT)

func animate_beam_pulse(core: Line2D, middle: Line2D, outer: Line2D):
	# Pulsing glow effect
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(core, "width", core.width * 1.3, 0.2)
	pulse_tween.tween_property(core, "width", core.width, 0.2)
	
	var middle_tween = create_tween().set_loops()
	middle_tween.tween_property(middle, "width", middle.width * 1.2, 0.3)
	middle_tween.tween_property(middle, "width", middle.width, 0.3)

func create_charge_effect():
	# Particles gather at player before firing
	var charge_particles = CPUParticles2D.new()
	charge_particles.global_position = global_position
	charge_particles.emitting = true
	charge_particles.one_shot = true
	charge_particles.amount = 15
	charge_particles.lifetime = 0.4
	charge_particles.explosiveness = 1.0
	charge_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	charge_particles.emission_sphere_radius = 50
	charge_particles.gravity = Vector2.ZERO
	charge_particles.direction = Vector2.ZERO
	charge_particles.initial_velocity_min = -100  # Negative = inward
	charge_particles.initial_velocity_max = -60
	charge_particles.color = Color(0.8, 0.5, 1)
	charge_particles.scale_amount_min = 2
	charge_particles.scale_amount_max = 5
	
	get_tree().current_scene.add_child(charge_particles)
	
	# Screen flash
	if player and player.has_method("shake_camera"):
		player.shake_camera(4)
	
	# Cleanup
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(charge_particles):
		charge_particles.queue_free()

func damage_enemies_in_beam(target_position: Vector2):
	# Deal damage multiple times during beam duration
	var ticks = 6  # Damage 6 times over duration
	var tick_damage = damage / ticks
	
	for i in range(ticks):
		await get_tree().create_timer(beam_duration / ticks).timeout
		
		# Damage all enemies in beam path
		damage_enemies_in_line(target_position, tick_damage)  # Pass tick_damage

func damage_enemies_in_line(target_position: Vector2, tick_damage: float):  # Add parameter
	var enemies = get_tree().get_nodes_in_group("enemies")
	var beam_start = global_position
	var beam_end = beam_start + (target_position - beam_start).normalized() * max_range
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# Check if enemy is close to the beam line
		var distance_to_line = point_to_line_distance(enemy.global_position, beam_start, beam_end)
		var distance_from_start = beam_start.distance_to(enemy.global_position)
		
		# Only damage if within beam width AND within beam length
		if distance_to_line < beam_width / 2 and distance_from_start < max_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(tick_damage)  # Now it has access to tick_damage
			flash_enemy(enemy)
			
func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	if line_len == 0:
		return point_vec.length()
	
	var t = clamp(point_vec.dot(line_vec) / (line_len * line_len), 0, 1)
	var projection = line_start + t * line_vec
	return point.distance_to(projection)

func flash_enemy(enemy: Node2D):
	var sprite = enemy.get_node_or_null("Sprite2D")
	if not sprite:
		return
	
	var original = sprite.modulate
	sprite.modulate = Color(2, 2, 2)
	
	await get_tree().create_timer(0.05).timeout
	if is_instance_valid(sprite):
		sprite.modulate = original

func fade_out_beam():
	if not current_beam:
		return
	
	var tween = create_tween()
	tween.tween_property(current_beam, "modulate:a", 0.0, 0.3)
	tween.tween_callback(current_beam.queue_free)
	current_beam = null

func upgrade():
	level += 1
	match level:
		2:
			max_range = 700.0  # Range increase
			damage *= 1.3
		3:
			max_range = 800.0  # Range increase
			beam_duration = 1.8
		4:
			max_range = 1000.0  # Range increase
			damage *= 1.4
		5:
			max_range = 1100.0  # Range increase
			cooldown = 4.0
		6:
			max_range = 1200.0  # Range increase
			beam_width = 55.0
			damage *= 1.5
		7:
			max_range = 1500.0  # Range increase
			beam_duration = 2.2
		8:
			max_range = 2000.0  # MASSIVE range
			damage *= 2.0
			cooldown = 3.0
			beam_width = 70.0
