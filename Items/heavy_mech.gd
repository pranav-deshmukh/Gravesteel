extends CharacterBody2D

signal died

var speed: float = randf_range(50, 70)
var health: float = 300.0
var max_health: float = 300.0
var armor: float = 0.5  # 50% damage reduction

@onready var player = get_tree().get_first_node_in_group("player")
@onready var missile_pods: Array = []

# Attack patterns
var missile_cooldown: float = 0.0
var missile_fire_interval: float = 3.0
var stomp_cooldown: float = 0.0
var stomp_interval: float = 5.0
var laser_sweep_cooldown: float = 0.0
var laser_sweep_interval: float = 7.0

# States
enum State { MOVING, MISSILE_ATTACK, STOMP, LASER_SWEEP }
var current_state: State = State.MOVING

func _ready():
	add_to_group("enemies")
	#create_mech_visual()
	create_health_bar()

func _physics_process(delta):
	if not player or not is_instance_valid(player):
		return
	
	# Update cooldowns
	missile_cooldown += delta
	stomp_cooldown += delta
	laser_sweep_cooldown += delta
	
	# State machine
	match current_state:
		State.MOVING:
			move_toward_player(delta)
			check_attack_patterns()
		State.MISSILE_ATTACK:
			fire_missiles()
			current_state = State.MOVING
		State.STOMP:
			execute_stomp()
			current_state = State.MOVING
		State.LASER_SWEEP:
			execute_laser_sweep()
			current_state = State.MOVING
	
	# Always rotate toward player
	#look_at(player.global_position)

func move_toward_player(delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	move_and_slide()
	
	# Screen shake from heavy footsteps
	if velocity.length() > 10:
		if fmod(Time.get_ticks_msec(), 500) < 10:
			if player and player.has_method("shake_camera"):
				player.shake_camera(3)

func check_attack_patterns():
	var distance = global_position.distance_to(player.global_position)
	
	# Close range stomp
	if stomp_cooldown >= stomp_interval and distance < 150:
		current_state = State.STOMP
		stomp_cooldown = 0.0
	
	# Medium range missiles
	elif missile_cooldown >= missile_fire_interval and distance < 600:
		current_state = State.MISSILE_ATTACK
		missile_cooldown = 0.0
	
	# Long range laser sweep
	elif laser_sweep_cooldown >= laser_sweep_interval:
		current_state = State.LASER_SWEEP
		laser_sweep_cooldown = 0.0

func create_mech_visual():
	# =========================
	# MAIN TORSO (Layered Armor)
	# =========================
	var torso = Polygon2D.new()
	torso.polygon = PackedVector2Array([
		Vector2(-40, -45),
		Vector2(40, -45),
		Vector2(45, 45),
		Vector2(-45, 45)
	])
	torso.color = Color(0.18, 0.18, 0.22)
	add_child(torso)

	# Inner armor plate
	var inner_plate = Polygon2D.new()
	inner_plate.polygon = PackedVector2Array([
		Vector2(-28, -30),
		Vector2(28, -30),
		Vector2(32, 30),
		Vector2(-32, 30)
	])
	inner_plate.color = Color(0.25, 0.25, 0.3)
	add_child(inner_plate)

	# =========================
	# CORE REACTOR (Glow)
	# =========================
	var core = Polygon2D.new()
	var core_points := PackedVector2Array()
	for i in range(12):
		var a = (i / 12.0) * TAU
		core_points.append(Vector2(cos(a), sin(a)) * 12)
	core.polygon = core_points
	core.color = Color(1.0, 0.4, 0.1, 0.9)
	core.position = Vector2(0, -10)
	add_child(core)

	# =========================
	# HEAD + VISOR
	# =========================
	var head = Polygon2D.new()
	head.polygon = PackedVector2Array([
		Vector2(-16, -14),
		Vector2(16, -14),
		Vector2(14, 10),
		Vector2(-14, 10)
	])
	head.color = Color(0.22, 0.22, 0.26)
	head.position = Vector2(0, -55)
	add_child(head)

	var visor = Polygon2D.new()
	visor.polygon = PackedVector2Array([
		Vector2(-10, -2),
		Vector2(10, -2),
		Vector2(8, 4),
		Vector2(-8, 4)
	])
	visor.color = Color(1, 0.2, 0.1, 0.9)
	visor.position = Vector2(0, -52)
	add_child(visor)

	# =========================
	# MISSILE PODS (Integrated)
	# =========================
	for side in [-1, 1]:
		var pod = Polygon2D.new()
		pod.polygon = PackedVector2Array([
			Vector2(-10, -18),
			Vector2(10, -18),
			Vector2(14, 18),
			Vector2(-14, 18)
		])
		pod.color = Color(0.35, 0.35, 0.4)
		pod.position = Vector2(side * 48, -18)
		add_child(pod)
		missile_pods.append(pod)

	# =========================
	# LEGS (Hydraulic Style)
	# =========================
	for side in [-1, 1]:
		var thigh = Polygon2D.new()
		thigh.polygon = PackedVector2Array([
			Vector2(-8, 0),
			Vector2(8, 0),
			Vector2(10, 40),
			Vector2(-10, 40)
		])
		thigh.color = Color(0.3, 0.3, 0.35)
		thigh.position = Vector2(side * 18, 45)
		add_child(thigh)

		var shin = Polygon2D.new()
		shin.polygon = PackedVector2Array([
			Vector2(-7, 0),
			Vector2(7, 0),
			Vector2(10, 42),
			Vector2(-10, 42)
		])
		shin.color = Color(0.25, 0.25, 0.3)
		shin.position = Vector2(side * 18, 85)
		add_child(shin)

		var foot = Polygon2D.new()
		foot.polygon = PackedVector2Array([
			Vector2(-16, 0),
			Vector2(16, 0),
			Vector2(14, 8),
			Vector2(-14, 8)
		])
		foot.color = Color(0.18, 0.18, 0.22)
		foot.position = Vector2(side * 18, 130)
		add_child(foot)

func create_health_bar():
	var health_bar = ProgressBar.new()
	health_bar.position = Vector2(-40, -80)
	health_bar.size = Vector2(80, 10)
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 0, 0, 0.8)
	health_bar.add_theme_stylebox_override("fill", style)
	
	add_child(health_bar)

func fire_missiles():
	print("Mech firing missiles!")
	
	for i in range(6):  # Fire 6 missiles
		await get_tree().create_timer(0.15).timeout
		
		var missile = create_missile()
		missile.global_position = global_position + Vector2(randf_range(-30, 30), -40)
		missile.target_position = player.global_position
		get_tree().current_scene.add_child(missile)

func create_missile() -> Node2D:
	var missile = Node2D.new()
	missile.set_script(preload("res://Items/tracking_missile.gd"))
	return missile

func execute_stomp():
	print("Mech executing stomp attack!")
	
	# Warning indicator
	var warning = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(16):
		var angle = (i / 16.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 150)
	warning.polygon = points
	warning.color = Color(1, 0, 0, 0.3)
	warning.global_position = global_position
	get_tree().current_scene.add_child(warning)
	
	# Flash warning
	var tween = create_tween().set_loops(3)
	tween.tween_property(warning, "color:a", 0.6, 0.3)
	tween.tween_property(warning, "color:a", 0.1, 0.3)
	
	await get_tree().create_timer(1.0).timeout
	
	# Execute stomp
	create_stomp_effect()
	warning.queue_free()
	
	# Damage player if in range
	var distance = global_position.distance_to(player.global_position)
	if distance < 150:
		if player and player.has_method("take_damage"):
			player.take_damage(30)
	
	# Massive screen shake
	if player and player.has_method("shake_camera"):
		player.shake_camera(40)

func create_stomp_effect():
	var shockwave = CPUParticles2D.new()
	shockwave.global_position = global_position
	shockwave.emitting = true
	shockwave.one_shot = true
	shockwave.amount = 50
	shockwave.lifetime = 0.8
	shockwave.direction = Vector2(1, 0)
	shockwave.spread = 180
	shockwave.initial_velocity_min = 200
	shockwave.initial_velocity_max = 400
	shockwave.scale_amount_min = 5
	shockwave.scale_amount_max = 12
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.8, 0.6, 0.3, 1))
	gradient.add_point(1.0, Color(0.3, 0.2, 0.1, 0))
	shockwave.color_ramp = gradient
	
	get_tree().current_scene.add_child(shockwave)
	
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(shockwave):
		shockwave.queue_free()

func execute_laser_sweep():
	print("Mech executing laser sweep!")
	
	var sweep_duration = 2.0
	var sweep_timer = 0.0
	var start_angle = rotation
	var sweep_range = PI / 2  # 90 degree sweep
	
	while sweep_timer < sweep_duration:
		await get_tree().create_timer(0.05).timeout
		sweep_timer += 0.05
		
		var progress = sweep_timer / sweep_duration
		var current_angle = start_angle - sweep_range / 2 + progress * sweep_range
		
		# Create laser beam
		var beam = Line2D.new()
		var beam_length = 800
		var beam_end = global_position + Vector2(cos(current_angle), sin(current_angle)) * beam_length
		
		beam.add_point(global_position)
		beam.add_point(beam_end)
		beam.width = 4
		beam.default_color = Color(1, 0, 0, 0.8)
		beam.z_index = 5
		
		get_tree().current_scene.add_child(beam)
		
		# Check if player is hit
		if player and is_instance_valid(player):
			var dist_to_line = point_to_line_distance(player.global_position, global_position, beam_end)
			if dist_to_line < 20:  # Hit detection radius
				if player.has_method("take_damage"):
					player.take_damage(5)
		
		# Remove beam after a moment
		await get_tree().create_timer(0.05).timeout
		if is_instance_valid(beam):
			beam.queue_free()

func point_to_line_distance(point: Vector2, line_start: Vector2, line_end: Vector2) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	var line_len = line_vec.length()
	var line_unitvec = line_vec / line_len
	var proj_length = point_vec.dot(line_unitvec)
	proj_length = clamp(proj_length, 0, line_len)
	var proj = line_unitvec * proj_length
	return (point_vec - proj).length()

func take_damage(amount: float = 1.0):
	# Apply armor reduction
	var reduced_damage = amount * (1.0 - armor)
	health -= reduced_damage
	
	# Update health bar
	if has_node("ProgressBar"):
		get_node("ProgressBar").value = health
	
	# Visual feedback
	modulate = Color(1, 0.3, 0.3)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func die():
	print("Heavy Mech destroyed!")
	
	# Epic explosion sequence
	for i in range(5):
		var explosion = CPUParticles2D.new()
		explosion.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		explosion.emitting = true
		explosion.one_shot = true
		explosion.amount = 60
		explosion.lifetime = 0.8
		explosion.explosiveness = 0.9
		explosion.spread = 180
		explosion.initial_velocity_min = 200
		explosion.initial_velocity_max = 500
		explosion.scale_amount_min = 5
		explosion.scale_amount_max = 15
		
		var gradient = Gradient.new()
		gradient.add_point(0.0, Color(1, 0.8, 0, 1))
		gradient.add_point(0.5, Color(1, 0.3, 0, 0.8))
		gradient.add_point(1.0, Color(0.3, 0.1, 0, 0))
		explosion.color_ramp = gradient
		
		get_tree().current_scene.add_child(explosion)
		
		await get_tree().create_timer(0.2).timeout
	
	# Mega screen shake
	if player and player.has_method("shake_camera"):
		player.shake_camera(60)
	
	# Drop lots of coins
	var coin_scene = preload("res://rewards/coins/coin.tscn")
	for i in range(10):
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
	
	if player and player.has_method("add_orcs_killed"):
		player.add_orcs_killed(5)
	
	died.emit()
	queue_free()
