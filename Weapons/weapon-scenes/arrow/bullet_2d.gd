extends Area2D

# Base properties
var damage: float = 10.0
var speed: float = 1000.0
var travelled_distance: float = 0.0
var max_range: float = 1200.0

# Advanced ammo properties
var ammo_type: String = "standard"
var pierce_count: int = 0
var explosion_radius: float = 0.0
var burn_duration: float = 0.0
var chain_count: int = 0

var enemies_hit: Array = []

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var velocity = Vector2.RIGHT.rotated(rotation) * speed
	position += velocity * delta
	
	travelled_distance += speed * delta
	if travelled_distance > max_range:
		queue_free()

func _on_body_entered(body):
	if not body.is_in_group("enemies"):
		return
	
	if body in enemies_hit:
		return
	
	enemies_hit.append(body)
	
	# Deal damage
	if body.has_method("take_damage"):
		body.take_damage(damage)
	
	# Special effects based on ammo type
	match ammo_type:
		"explosive":
			create_explosion()
		"incendiary":
			apply_burn_effect(body)
		"chain_lightning":
			chain_to_nearby_enemies(body)
	
	# Pierce logic
	if pierce_count > 0:
		pierce_count -= 1
	else:
		queue_free()

func create_explosion():
	# Create explosion particles
	var explosion = CPUParticles2D.new()
	explosion.global_position = global_position
	explosion.emitting = true
	explosion.one_shot = true
	explosion.amount = 30
	explosion.lifetime = 0.4
	explosion.explosiveness = 0.9
	explosion.spread = 180
	explosion.initial_velocity_min = 100
	explosion.initial_velocity_max = 300
	explosion.scale_amount_min = 4
	explosion.scale_amount_max = 10
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 1, 0.3, 1))
	gradient.add_point(0.5, Color(1, 0.3, 0, 0.8))
	gradient.add_point(1.0, Color(0.2, 0.1, 0, 0))
	explosion.color_ramp = gradient
	
	get_tree().current_scene.add_child(explosion)
	
	# Damage nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < explosion_radius:
				var splash_damage = damage * 0.5 * (1.0 - dist / explosion_radius)
				if enemy.has_method("take_damage"):
					enemy.take_damage(splash_damage)
	
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(explosion):
		explosion.queue_free()

func apply_burn_effect(enemy):
	# Create fire particles on enemy
	var fire = CPUParticles2D.new()
	fire.emitting = true
	fire.amount = 8
	fire.lifetime = 0.6
	fire.spread = 30
	fire.direction = Vector2(0, -1)
	fire.initial_velocity_min = 20
	fire.initial_velocity_max = 50
	fire.gravity = Vector2(0, -30)
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.8, 0, 1))
	gradient.add_point(0.5, Color(1, 0.2, 0, 0.8))
	gradient.add_point(1.0, Color(0.3, 0, 0, 0))
	fire.color_ramp = gradient
	
	enemy.add_child(fire)
	
	# Apply DoT (Damage over Time)
	var burn_timer = Timer.new()
	burn_timer.wait_time = 0.5
	burn_timer.timeout.connect(func(): 
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(damage * 0.2)
	)
	enemy.add_child(burn_timer)
	burn_timer.start()
	
	await get_tree().create_timer(burn_duration).timeout
	if is_instance_valid(fire):
		fire.queue_free()
	if is_instance_valid(burn_timer):
		burn_timer.queue_free()

func chain_to_nearby_enemies(origin_enemy):
	if chain_count <= 0:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_enemy = null
	var closest_dist = 300.0
	
	for enemy in enemies:
		if enemy == origin_enemy or enemy in enemies_hit:
			continue
		if is_instance_valid(enemy):
			var dist = origin_enemy.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest_enemy = enemy
	
	if closest_enemy:
		# Create lightning arc
		create_lightning_arc(origin_enemy.global_position, closest_enemy.global_position)
		
		# Damage chained enemy
		if closest_enemy.has_method("take_damage"):
			closest_enemy.take_damage(damage * 0.7)
		
		enemies_hit.append(closest_enemy)
		chain_count -= 1
		
		# Continue chain
		if chain_count > 0:
			chain_to_nearby_enemies(closest_enemy)

func create_lightning_arc(from: Vector2, to: Vector2):
	var arc = Line2D.new()
	
	# Create jagged lightning path
	var steps = 8
	arc.add_point(from)
	for i in range(1, steps):
		var t = float(i) / float(steps)
		var mid_point = from.lerp(to, t)
		mid_point += Vector2(randf_range(-20, 20), randf_range(-20, 20))
		arc.add_point(mid_point)
	arc.add_point(to)
	
	arc.width = 2
	arc.default_color = Color(0, 1, 1, 1)
	arc.z_index = 10
	
	get_tree().current_scene.add_child(arc)
	
	var tween = create_tween()
	tween.tween_property(arc, "default_color:a", 0.0, 0.2)
	tween.tween_callback(arc.queue_free)
