class_name BoomerangBlades
extends Node2D

@export var damage: float = 18.0
@export var blade_count: int = 1
@export var throw_speed: float = 700.0
@export var return_speed: float = 700.0
@export var max_distance: float = 350.0
@export var throw_interval: float = 2.5
@export var level: int = 1

var player
var is_on_cooldown: bool = false

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _process(_delta):
	if player and is_instance_valid(player):
		global_position = player.global_position
	
	if not is_on_cooldown:
		throw_blades()

func throw_blades():
	var target = find_nearest_enemy()
	if not target:
		await get_tree().create_timer(0.5).timeout
		return
	
	is_on_cooldown = true
	
	# Throw multiple blades with spread
	for i in range(blade_count):
		var direction = (target.global_position - global_position).normalized()
		
		# Add spread angle
		if blade_count > 1:
			var spread_angle = (i - (blade_count - 1) / 2.0) * 25.0
			direction = direction.rotated(deg_to_rad(spread_angle))
		
		spawn_boomerang(direction)
		await get_tree().create_timer(0.1).timeout  # Slight delay between blades
	
	# Cooldown
	await get_tree().create_timer(throw_interval).timeout
	is_on_cooldown = false

func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return null
	
	var nearest = null
	var min_distance = INF
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < min_distance:
				min_distance = distance
				nearest = enemy
	
	return nearest

func spawn_boomerang(direction: Vector2):
	var boomerang = create_boomerang_blade()
	boomerang.global_position = global_position
	boomerang.rotation = direction.angle()
	
	# Set blade data directly (after adding to scene so _ready() runs)
	get_tree().current_scene.add_child(boomerang)
	
	boomerang.direction = direction
	boomerang.distance_traveled = 0.0
	boomerang.returning = false
	boomerang.throw_position = global_position
	boomerang.hit_enemies = []
	boomerang.weapon = self
	
	# Camera shake on throw
	if player and player.has_method("shake_camera"):
		player.shake_camera(4)
func create_boomerang_blade() -> Area2D:
	var blade = Area2D.new()
	blade.name = "Boomerang"
	blade.collision_layer = 0
	blade.collision_mask = 2  # Enemies layer
	
	# Load the script
	var script = load("res://Weapons/Projectile_Weapons/boomerang_blades/boomerang_projectile.gd")  # UPDATE THIS PATH
	blade.set_script(script)
	
	# Curved blade visual
	var visual = create_blade_visual()
	blade.add_child(visual)
	
	# Collision shape
	var collision = CollisionShape2D.new()
	var shape = CapsuleShape2D.new()
	shape.radius = 8
	shape.height = 40
	collision.shape = shape
	collision.rotation = PI / 2  # Horizontal
	blade.add_child(collision)
	
	# Trail effect
	var trail = create_trail_effect()
	blade.add_child(trail)
	
	# Connect hit detection
	blade.body_entered.connect(func(body): _on_blade_hit(blade, body))
	
	return blade


func create_blade_visual() -> Node2D:
	var visual = Node2D.new()
	visual.name = "Visual"
	
	# Load your boomerang scene
	var boomerang_scene = preload("res://Weapons/Projectile_Weapons/boomerang_blades/boomerang.tscn")
	var animated_sprite = boomerang_scene.instantiate()
	
	# Play the animation
	if animated_sprite.has_method("play"):
		animated_sprite.play()
	
	#animated_sprite.scale = Vector2(0.5, 0.5)  # Adjust size
	
	visual.add_child(animated_sprite)
	
	return visual
	
func create_trail_effect() -> Line2D:
	var trail = Line2D.new()
	trail.name = "Trail"
	trail.width = 3
	trail.default_color = Color(0.6, 0.6, 0.8, 0.5)  # Gray-blue trail
	trail.z_index = -1
	
	# Gradient for fading trail
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.8, 1, 0))    # Transparent at back
	gradient.add_point(1.0, Color(0.6, 0.6, 0.8, 0.7))  # Visible at front
	trail.gradient = gradient
	
	return trail


func _on_blade_hit(blade: Area2D, body: Node2D):
	if not body.is_in_group("enemies"):
		return
	
	# Check if hit_enemies exists and is valid
	if not "hit_enemies" in blade or blade.hit_enemies == null:
		blade.hit_enemies = []
	
	if body in blade.hit_enemies:
		return
	
	if body.has_method("take_damage"):
		var returning = blade.returning if "returning" in blade else false
		var hit_damage = damage
		if returning:
			hit_damage *= 1.3
		
		body.take_damage(hit_damage)
	
	blade.hit_enemies.append(body)
	
	create_slash_effect(body.global_position, blade.rotation)
	flash_enemy(body)
	
	if player and player.has_method("shake_camera"):
		player.shake_camera(3)
		
func create_slash_effect(pos: Vector2, angle: float):
	var slash = Node2D.new()
	slash.global_position = pos
	slash.rotation = angle
	slash.z_index = 5
	
	var arc = Line2D.new()
	arc.width = 3
	arc.default_color = Color(1, 1, 1, 0.9)
	
	for i in range(7):
		var progress = i / 6.0
		var arc_angle = -PI/4 + progress * PI/2
		var radius = 25
		arc.add_point(Vector2(cos(arc_angle), sin(arc_angle)) * radius)
	
	slash.add_child(arc)
	
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	particles.spread = 60
	particles.direction = Vector2.RIGHT.rotated(angle)
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 120
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = Color(0.8, 0.8, 1)
	slash.add_child(particles)
	
	get_tree().current_scene.add_child(slash)
	
	var tween = create_tween()
	tween.tween_property(arc, "default_color:a", 0.0, 0.2)
	tween.tween_callback(slash.queue_free)

func create_catch_effect(pos: Vector2):
	var catch_fx = Node2D.new()
	catch_fx.global_position = pos
	catch_fx.z_index = 5
	
	var ring = Polygon2D.new()
	ring.polygon = create_circle_polygon(15, 24)
	ring.color = Color(0.7, 0.7, 1, 0.6)
	catch_fx.add_child(ring)
	
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 30
	particles.initial_velocity_max = 80
	particles.scale_amount_min = 2
	particles.scale_amount_max = 4
	particles.color = Color(1, 1, 1)
	catch_fx.add_child(particles)
	
	get_tree().current_scene.add_child(catch_fx)
	
	var tween = create_tween()
	tween.tween_property(ring, "scale", Vector2(2, 2), 0.3)
	tween.parallel().tween_property(ring, "color:a", 0.0, 0.3)
	tween.tween_callback(catch_fx.queue_free)
	
	if player and player.has_method("shake_camera"):
		player.shake_camera(2)

func flash_enemy(enemy: Node2D):
	var sprite = enemy.get_node_or_null("Sprite2D")
	if not sprite:
		return
	
	var original = sprite.modulate
	sprite.modulate = Color(2, 2, 2)
	
	await get_tree().create_timer(0.1).timeout
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
			damage *= 1.4
			return_speed = 800.0
		3:
			blade_count = 2
			max_distance = 400.0
		4:
			damage *= 1.3
			throw_speed = 870.0
		5:
			max_distance = 480.0
			throw_interval = 2.0
		6:
			blade_count = 3
			damage *= 1.5
		7:
			return_speed = 870.0
			max_distance = 550.0
		8:
			blade_count = 4
			damage *= 2.0
			throw_interval = 1.5
