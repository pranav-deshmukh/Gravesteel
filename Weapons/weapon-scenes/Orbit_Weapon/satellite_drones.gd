class_name SatelliteDrones
extends Node2D

@export var damage: float = 8.0
@export var drone_count: int = 2
@export var orbit_radius: float = 80.0
@export var orbit_speed: float = 2.0
@export var fire_rate: float = 2.0  # Shots per second per drone
@export var laser_range: float = 400.0
@export var level: int = 1

var player
var drones: Array = []
var orbit_angle: float = 0.0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	spawn_drones()

func _process(delta):
	if player and is_instance_valid(player):
		global_position = player.global_position
	
	# Update orbit
	orbit_angle += orbit_speed * delta
	update_drone_positions(delta)

func spawn_drones():
	for i in range(drone_count):
		var drone = create_drone(i)
		drones.append(drone)
		add_child(drone)

func create_drone(index: int) -> Node2D:
	var drone = Node2D.new()
	drone.name = "Drone" + str(index)
	
	# Visual - glowing orb
	var sprite = Sprite2D.new()
	# If you have a drone sprite, use it. Otherwise create a simple circle
	var circle = create_drone_visual()
	drone.add_child(circle)
	
	# Targeting system
	var target_marker = Line2D.new()
	target_marker.name = "TargetLine"
	target_marker.width = 1
	target_marker.default_color = Color(0, 1, 1, 0.3)  # Cyan, transparent
	target_marker.z_index = -1
	drone.add_child(target_marker)
	
	# Fire timer - each drone fires independently
	var fire_timer = Timer.new()
	fire_timer.name = "FireTimer"
	fire_timer.wait_time = 1.0 / fire_rate
	fire_timer.timeout.connect(func(): fire_laser(drone))
	fire_timer.autostart = true
	drone.add_child(fire_timer)
	
	# Drone data
	drone.set_meta("index", index)
	drone.set_meta("current_target", null)
	
	return drone

func create_drone_visual() -> Node2D:
	# Create a glowing orb effect
	var visual = Node2D.new()
	
	# Outer glow
	var outer_glow = Polygon2D.new()
	outer_glow.polygon = create_circle_polygon(12, 12)
	outer_glow.color = Color(0.2, 0.6, 1.0, 0.3)  # Blue glow
	visual.add_child(outer_glow)
	
	# Inner core
	var core = Polygon2D.new()
	core.polygon = create_circle_polygon(8, 8)
	core.color = Color(0.5, 0.9, 1.0, 1.0)  # Bright cyan
	visual.add_child(core)
	
	# Center dot
	var center = Polygon2D.new()
	center.polygon = create_circle_polygon(3, 3)
	center.color = Color(1, 1, 1, 1)  # White center
	visual.add_child(center)
	
	# Add pulsing animation
	var tween = create_tween().set_loops()
	tween.tween_property(core, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(core, "scale", Vector2(1.0, 1.0), 0.5)
	
	return visual

func create_circle_polygon(radius: float, points: int) -> PackedVector2Array:
	var polygon = PackedVector2Array()
	for i in range(points):
		var angle = (i / float(points)) * TAU
		polygon.append(Vector2(cos(angle), sin(angle)) * radius)
	return polygon

func update_drone_positions(delta):
	for i in range(drones.size()):
		var drone = drones[i]
		var angle_offset = (TAU / drone_count) * i
		var angle = orbit_angle + angle_offset
		
		# Circular orbit
		drone.position = Vector2(
			cos(angle) * orbit_radius,
			sin(angle) * orbit_radius
		)
		
		# Find and track target
		var target = find_target_for_drone(drone)
		drone.set_meta("current_target", target)
		
		# Update targeting line
		update_target_line(drone, target)

func find_target_for_drone(drone: Node2D) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
	
	var drone_global_pos = drone.global_position
	var closest = null
	var closest_dist = laser_range
	
	# Find closest enemy in range
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = drone_global_pos.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	
	return closest

func update_target_line(drone: Node2D, target: Node2D):
	var line = drone.get_node_or_null("TargetLine")
	if not line:
		return
	
	line.clear_points()
	
	if target and is_instance_valid(target):
		# Draw line to target
		var local_target_pos = target.global_position - drone.global_position
		line.add_point(Vector2.ZERO)
		line.add_point(local_target_pos)
		line.default_color = Color(1, 0.3, 0.3, 0.5)  # Red when locked
	else:
		line.default_color = Color(0, 1, 1, 0.2)  # Cyan when searching

func fire_laser(drone: Node2D):
	var target = drone.get_meta("current_target")
	
	if not target or not is_instance_valid(target):
		return
	
	# Check if still in range
	var dist = drone.global_position.distance_to(target.global_position)
	if dist > laser_range:
		return
	
	# Create laser beam
	create_laser_beam(drone.global_position, target.global_position)
	
	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage)
	
	# Effects
	create_hit_effect(target.global_position)
	play_laser_sound()
	
	# Small screen shake
	if player and player.has_method("shake_camera"):
		player.shake_camera(2)

func create_laser_beam(from: Vector2, to: Vector2):
	var beam = Line2D.new()
	beam.add_point(from)
	beam.add_point(to)
	beam.width = 2
	beam.default_color = Color(0, 1, 1, 1)  # Cyan laser
	beam.z_index = 10
	
	get_tree().current_scene.add_child(beam)
	
	# Beam fades out quickly
	var tween = create_tween()
	tween.tween_property(beam, "default_color:a", 0.0, 0.15)
	tween.tween_callback(beam.queue_free)

func create_hit_effect(pos: Vector2):
	# Electric spark particles
	var particles = CPUParticles2D.new()
	particles.global_position = pos
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 6
	particles.lifetime = 0.2
	particles.explosiveness = 1.0
	particles.spread = 180
	
	# Cyan/blue particles
	particles.color = Color(0, 1, 1)
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 80
	particles.scale_amount_min = 1
	particles.scale_amount_max = 3
	
	get_tree().current_scene.add_child(particles)
	
	await get_tree().create_timer(0.3).timeout
	if is_instance_valid(particles):
		particles.queue_free()
	
	# Digital hit marker UI
	show_target_lock_ui(pos)

func show_target_lock_ui(pos: Vector2):
	# Create targeting reticle
	var reticle = Node2D.new()
	reticle.global_position = pos
	
	# Four corner brackets
	for i in range(4):
		var bracket = Line2D.new()
		var angle = (PI / 2) * i
		var offset = Vector2(10, 10).rotated(angle)
		
		bracket.add_point(offset)
		bracket.add_point(offset * 0.5)
		bracket.width = 2
		bracket.default_color = Color(0, 1, 1)
		reticle.add_child(bracket)
	
	get_tree().current_scene.add_child(reticle)
	
	# Animate and fade
	var tween = create_tween()
	tween.tween_property(reticle, "scale", Vector2(1.5, 1.5), 0.2)
	tween.parallel().tween_property(reticle, "modulate:a", 0.0, 0.2)
	tween.tween_callback(reticle.queue_free)

func play_laser_sound():
	# TODO: Add AudioStreamPlayer with sci-fi pew sound
	# pitch_scale = randf_range(0.9, 1.1) for variety
	pass

func upgrade():
	level += 1
	match level:
		2:
			damage *= 1.3
			fire_rate *= 1.2
			update_fire_timers()
		3:
			drone_count = 3
			spawn_new_drone()
		4:
			laser_range *= 1.3
			orbit_speed *= 1.2
		5:
			damage *= 1.5
			fire_rate *= 1.3
			update_fire_timers()
		6:
			drone_count = 4
			spawn_new_drone()
		7:
			damage *= 1.4
			laser_range *= 1.5
			orbit_radius *= 1.2
		8:
			drone_count = 6
			damage *= 2.0
			fire_rate *= 1.5
			update_fire_timers()
			spawn_new_drone()
			spawn_new_drone()

func spawn_new_drone():
	var new_drone = create_drone(drones.size())
	drones.append(new_drone)
	add_child(new_drone)

func update_fire_timers():
	for drone in drones:
		var timer = drone.get_node_or_null("FireTimer")
		if timer:
			timer.wait_time = 1.0 / fire_rate
