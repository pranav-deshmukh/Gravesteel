class_name LightningStrike
extends Node2D

@export var damage: float = 25.0
@export var strike_count: int = 3  # Strikes per volley
@export var strike_interval: float = 3.0  # Time between volleys
@export var chain_range: float = 150.0  # Distance lightning can chain
@export var max_chains: int = 2  # How many times it bounces
@export var level: int = 1

var player
var is_striking: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")
	start_strike_cycle()

func _process(_delta):
	if player and is_instance_valid(player):
		global_position = player.global_position

func start_strike_cycle():
	while true:
		await get_tree().create_timer(strike_interval).timeout
		if not is_striking:
			trigger_lightning_volley()

func trigger_lightning_volley():
	is_striking = true
	
	# Spawn multiple lightning strikes with slight delays
	for i in range(strike_count):
		spawn_lightning()
		await get_tree().create_timer(0.2).timeout  # Stagger strikes
	
	is_striking = false

func spawn_lightning():
	# Find random enemy
	var target = find_random_enemy()
	if not target:
		return
	
	# Warning flash
	create_warning_flash(target.global_position)
	
	# Brief delay before strike
	await get_tree().create_timer(0.3).timeout
	
	if is_instance_valid(target):
		# Strike!
		create_lightning_bolt(target.global_position)
		damage_and_chain(target)

func find_random_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
	
	# Filter to enemies within reasonable range
	var nearby_enemies = []
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 600:  # Don't strike too far away
				nearby_enemies.append(enemy)
	
	if nearby_enemies.size() == 0:
		return null
	
	return nearby_enemies[randi() % nearby_enemies.size()]

func create_warning_flash(pos: Vector2):
	var warning = Node2D.new()
	warning.global_position = pos
	warning.z_index = 10
	
	# Lightning bolt icon (simple zig-zag)
	var icon = Line2D.new()
	icon.width = 3
	icon.default_color = Color(1, 1, 0, 0.8)  # Yellow
	
	# Zig-zag pattern
	icon.add_point(Vector2(0, -20))
	icon.add_point(Vector2(10, -10))
	icon.add_point(Vector2(-5, 0))
	icon.add_point(Vector2(10, 10))
	icon.add_point(Vector2(0, 20))
	
	warning.add_child(icon)
	
	# Pulsing circle
	var circle = Polygon2D.new()
	circle.polygon = create_circle_polygon(30, 24)
	circle.color = Color(1, 1, 0, 0.2)
	warning.add_child(circle)
	
	# Quick pulse
	var tween = create_tween().set_loops(2)
	tween.tween_property(circle, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(circle, "scale", Vector2(1.0, 1.0), 0.15)
	
	get_tree().current_scene.add_child(warning)
	
	# Remove after warning
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(warning):
		warning.queue_free()

func create_lightning_bolt(target_pos: Vector2):
	var bolt = Node2D.new()
	bolt.name = "LightningBolt"
	bolt.z_index = 5
	
	# Start from high above
	var start_pos = target_pos + Vector2(randf_range(-50, 50), -800)
	bolt.global_position = Vector2.ZERO
	
	# Main bolt (thick, bright white)
	var main_bolt = create_bolt_line(start_pos, target_pos, 8, Color(1, 1, 1, 1))
	bolt.add_child(main_bolt)
	
	# Inner glow (cyan)
	var glow = create_bolt_line(start_pos, target_pos, 15, Color(0.5, 0.8, 1, 0.6))
	bolt.add_child(glow)
	
	# Outer glow (blue, transparent)
	var outer = create_bolt_line(start_pos, target_pos, 25, Color(0.3, 0.5, 1, 0.3))
	bolt.add_child(outer)
	
	# Branch bolts (smaller offshoots)
	create_branch_bolts(bolt, start_pos, target_pos)
	
	get_tree().current_scene.add_child(bolt)
	
	# Impact flash at ground
	create_impact_flash(target_pos)
	
	# Electric particles
	create_electric_particles(target_pos)
	
	# Screen flash white
	create_screen_flash()
	
	# BIG screen shake
	if player and player.has_method("shake_camera"):
		player.shake_camera(12)
	
	# Play thunder sound (TODO: add AudioStreamPlayer)
	
	# Bolt flickers and fades
	flicker_and_fade(bolt)

func create_bolt_line(from: Vector2, to: Vector2, width: float, color: Color) -> Line2D:
	var line = Line2D.new()
	line.width = width
	line.default_color = color
	
	# Create jagged lightning path
	var points = generate_lightning_path(from, to, 8)
	for point in points:
		line.add_point(point)
	
	return line

func generate_lightning_path(from: Vector2, to: Vector2, segments: int) -> Array:
	var points = [from]
	var direction = (to - from)
	var segment_length = direction.length() / segments
	direction = direction.normalized()
	
	for i in range(1, segments):
		var progress = i / float(segments)
		var base_point = from + direction * (segment_length * i)
		
		# Add random offset perpendicular to direction
		var perpendicular = Vector2(-direction.y, direction.x)
		var offset = perpendicular * randf_range(-40, 40)
		
		points.append(base_point + offset)
	
	points.append(to)
	return points

func create_branch_bolts(parent: Node2D, from: Vector2, to: Vector2):
	# Create 2-3 branch bolts
	var branch_count = randi_range(2, 3)
	
	for i in range(branch_count):
		var progress = randf_range(0.2, 0.7)  # Branch from middle section
		var branch_start = from.lerp(to, progress)
		
		# Branch goes sideways
		var direction = (to - from).normalized()
		var perpendicular = Vector2(-direction.y, direction.x)
		var side = 1 if randf() > 0.5 else -1
		var branch_end = branch_start + perpendicular * side * randf_range(50, 120)
		
		var branch = Line2D.new()
		branch.width = 4
		branch.default_color = Color(0.8, 0.9, 1, 0.8)
		
		var branch_points = generate_lightning_path(branch_start, branch_end, 4)
		for point in branch_points:
			branch.add_point(point)
		
		parent.add_child(branch)

func create_impact_flash(pos: Vector2):
	var flash = Node2D.new()
	flash.global_position = pos
	flash.z_index = 4
	
	# Expanding circles
	for i in range(3):
		var circle = Polygon2D.new()
		circle.polygon = create_circle_polygon(20 + i * 15, 24)
		circle.color = Color(1, 1, 0.8, 0.6 - i * 0.2)
		flash.add_child(circle)
		
		var tween = create_tween()
		tween.tween_property(circle, "scale", Vector2(2, 2), 0.3)
		tween.parallel().tween_property(circle, "color:a", 0.0, 0.3)
	
	# Star burst lines
	for i in range(8):
		var line = Line2D.new()
		var angle = (i / 8.0) * TAU
		var dir = Vector2(cos(angle), sin(angle))
		line.add_point(Vector2.ZERO)
		line.add_point(dir * 40)
		line.width = 3
		line.default_color = Color(1, 1, 0.5)
		flash.add_child(line)
		
		# Store reference to line for tween
		var line_ref = line
		var tween = create_tween()
		tween.tween_method(func(val):
			if is_instance_valid(line_ref) and line_ref.get_point_count() > 1:
				line_ref.set_point_position(1, dir * val)
		, 0.0, 60.0, 0.2)
		tween.parallel().tween_property(line, "default_color:a", 0.0, 0.2)
	
	get_tree().current_scene.add_child(flash)
	
	await get_tree().create_timer(0.4).timeout
	if is_instance_valid(flash):
		flash.queue_free()
		
func create_electric_particles(pos: Vector2):
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 20
	particles.spread = 180
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 200
	particles.scale_amount_min = 2
	particles.scale_amount_max = 5
	
	# Electric blue/white gradient
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 1))
	gradient.add_point(0.5, Color(0.5, 0.8, 1))
	gradient.add_point(1.0, Color(0.3, 0.5, 1, 0))
	particles.color_ramp = gradient
	
	get_tree().current_scene.add_child(particles)
	
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func flicker_and_fade(bolt: Node2D):
	# Lightning flickers a few times before disappearing
	var flicker_count = 3
	
	for i in range(flicker_count):
		bolt.visible = false
		await get_tree().create_timer(0.05).timeout
		bolt.visible = true
		await get_tree().create_timer(0.03).timeout
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(bolt, "modulate:a", 0.0, 0.1)
	tween.tween_callback(bolt.queue_free)

func create_screen_flash():
	var flash = ColorRect.new()
	flash.color = Color(1, 1, 1, 0.4)  # Bright white flash
	flash.size = get_viewport().get_visible_rect().size * 2
	flash.position = -flash.size / 2
	flash.z_index = 100
	
	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.add_child(flash)
		
		var tween = create_tween()
		tween.tween_property(flash, "color:a", 0.0, 0.15)
		tween.tween_callback(flash.queue_free)

func damage_and_chain(initial_target: Node2D):
	var hit_enemies = []
	var current_pos: Vector2
	
	# Damage initial target
	if is_instance_valid(initial_target):
		current_pos = initial_target.global_position
		if initial_target.has_method("take_damage"):
			initial_target.take_damage(damage)
		hit_enemies.append(initial_target)
		flash_enemy(initial_target)
	else:
		return
	
	# Chain to nearby enemies
	for chain_num in range(max_chains):
		await get_tree().create_timer(0.1).timeout
		
		var next_target = find_chain_target(current_pos, hit_enemies)
		if not next_target:
			break
		
		# Visual chain lightning
		create_chain_bolt(current_pos, next_target.global_position)
		
		# Update current position
		current_pos = next_target.global_position
		
		# Damage
		if next_target.has_method("take_damage"):
			var chain_damage = damage * 0.7  # Reduced damage for chains
			next_target.take_damage(chain_damage)
		
		hit_enemies.append(next_target)
		flash_enemy(next_target)

func find_chain_target(from_pos: Vector2, already_hit: Array) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest = null
	var closest_dist = chain_range
	
	for enemy in enemies:
		if enemy in already_hit or not is_instance_valid(enemy):
			continue
		
		var dist = from_pos.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy
	
	return closest

func create_chain_bolt(from: Vector2, to: Vector2):
	var chain = Node2D.new()
	chain.z_index = 5
	
	# Thinner chain bolt
	var bolt = Line2D.new()
	bolt.width = 5
	bolt.default_color = Color(0.7, 0.9, 1, 1)  # Cyan
	
	var points = generate_lightning_path(from, to, 4)
	for point in points:
		bolt.add_point(point)
	
	chain.add_child(bolt)
	
	get_tree().current_scene.add_child(chain)
	
	# Quick flicker and fade
	await get_tree().create_timer(0.05).timeout
	chain.visible = false
	await get_tree().create_timer(0.03).timeout
	chain.visible = true
	
	var tween = create_tween()
	tween.tween_property(chain, "modulate:a", 0.0, 0.1)
	tween.tween_callback(chain.queue_free)

func flash_enemy(enemy: Node2D):
	var sprite = enemy.get_node_or_null("Sprite2D")
	if not sprite:
		return
	
	var original = sprite.modulate
	sprite.modulate = Color(3, 3, 3)  # Bright white
	
	await get_tree().create_timer(0.08).timeout
	if is_instance_valid(sprite):
		sprite.modulate = original

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
			strike_count = 4
			damage *= 1.3
		3:
			max_chains = 3
			chain_range = 180.0
		4:
			strike_count = 5
			damage *= 1.4
		5:
			max_chains = 4
			strike_interval = 2.5
		6:
			strike_count = 6
			chain_range = 220.0
			damage *= 1.5
		7:
			max_chains = 5
			strike_interval = 2.0
		8:
			strike_count = 8
			max_chains = 6
			damage *= 2.0
			chain_range = 300.0
