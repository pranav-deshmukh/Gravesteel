extends CharacterBody2D

signal died

var speed: float = randf_range(120, 150)
var health: float = 25.0
var damage: float = 8.0
var hover_height: float = 50.0
var hover_speed: float = 3.0
var hover_offset: float = 0.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var laser_weapon: Node2D = create_laser_weapon()
@onready var shield_visual: Polygon2D = create_shield()

var has_shield: bool = true
var shield_health: float = 15.0
var max_shield: float = 15.0
var shield_regen_timer: float = 0.0

func _ready():
	add_to_group("enemies")
	add_child(laser_weapon)
	add_child(shield_visual)
	#create_drone_visual()

func _physics_process(delta):
	if not player or not is_instance_valid(player):
		return
	
	# Hover animation
	hover_offset += hover_speed * delta
	var hover = sin(hover_offset) * hover_height
	
	# Move toward player with hover
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * speed
	velocity.y += hover
	move_and_slide()
	
	# Rotate toward player
	look_at(player.global_position)
	
	# Fire laser at player
	fire_laser_at_player(delta)
	
	# Shield regeneration
	if shield_health < max_shield:
		shield_regen_timer += delta
		if shield_regen_timer > 3.0:  # 3 seconds to start regen
			shield_health = min(shield_health + 5.0 * delta, max_shield)
			has_shield = shield_health > 0
	
	# Update shield visual
	update_shield_visual()

func create_drone_visual():
	# Main body (hexagon)
	var body = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(6):
		var angle = (i / 6.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 15)
	body.polygon = points
	body.color = Color(0.3, 0.3, 0.4)
	add_child(body)
	
	# Red eye
	var eye = Polygon2D.new()
	var eye_points = PackedVector2Array()
	for i in range(8):
		var angle = (i / 8.0) * TAU
		eye_points.append(Vector2(cos(angle), sin(angle)) * 5)
	eye.polygon = eye_points
	eye.color = Color(1, 0, 0, 0.8)
	add_child(eye)
	
	# Propellers
	for i in range(4):
		var prop = Polygon2D.new()
		var prop_angle = (i / 4.0) * TAU
		var offset = Vector2(cos(prop_angle), sin(prop_angle)) * 20
		var prop_points = PackedVector2Array([
			offset + Vector2(-3, -1),
			offset + Vector2(3, -1),
			offset + Vector2(3, 1),
			offset + Vector2(-3, 1)
		])
		prop.polygon = prop_points
		prop.color = Color(0.5, 0.5, 0.5)
		add_child(prop)
		
		# Animate propellers
		var tween = create_tween().set_loops()
		tween.tween_property(prop, "rotation", TAU, 0.2)

func create_laser_weapon() -> Node2D:
	var weapon = Node2D.new()
	weapon.name = "LaserWeapon"
	
	# Weapon barrel
	var barrel = Polygon2D.new()
	barrel.polygon = PackedVector2Array([
		Vector2(10, -2),
		Vector2(25, -1),
		Vector2(25, 1),
		Vector2(10, 2)
	])
	barrel.color = Color(0.7, 0.2, 0.2)
	weapon.add_child(barrel)
	
	return weapon

func create_shield() -> Polygon2D:
	var shield = Polygon2D.new()
	var points = PackedVector2Array()
	for i in range(12):
		var angle = (i / 12.0) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 25)
	shield.polygon = points
	shield.color = Color(0, 0.5, 1, 0.3)
	return shield

func update_shield_visual():
	if has_shield and shield_health > 0:
		shield_visual.visible = true
		var alpha = (shield_health / max_shield) * 0.3
		shield_visual.color = Color(0, 0.5, 1, alpha)
		
		# Pulse when low
		if shield_health < max_shield * 0.3:
			var pulse = abs(sin(Time.get_ticks_msec() / 100.0))
			shield_visual.color.a = alpha * pulse
	else:
		shield_visual.visible = false

func fire_laser_at_player(delta):
	# Simple laser attack every 2 seconds
	if not has_node("FireTimer"):
		var timer = Timer.new()
		timer.name = "FireTimer"
		timer.wait_time = 2.0
		timer.timeout.connect(shoot_laser)
		timer.autostart = true
		add_child(timer)

func shoot_laser():
	if not player or not is_instance_valid(player):
		return
	
	# Create laser beam
	var beam = Line2D.new()
	beam.add_point(global_position)
	beam.add_point(player.global_position)
	beam.width = 2
	beam.default_color = Color(1, 0, 0, 1)
	beam.z_index = 5
	
	get_tree().current_scene.add_child(beam)
	
	# Damage player
	if player.has_method("take_damage"):
		player.take_damage(damage)
	
	# Fade out beam
	var tween = create_tween()
	tween.tween_property(beam, "default_color:a", 0.0, 0.2)
	tween.tween_callback(beam.queue_free)

func take_damage(amount: float = 1.0):
	# Shield absorbs damage first
	if has_shield and shield_health > 0:
		shield_health -= amount
		shield_regen_timer = 0.0
		
		# Shield break effect
		if shield_health <= 0:
			has_shield = false
			create_shield_break_effect()
		return
	
	# Direct hull damage
	health -= amount
	
	# Visual feedback
	modulate = Color(1, 0.5, 0.5)
	await get_tree().create_timer(0.1).timeout
	modulate = Color(1, 1, 1)
	
	if health <= 0:
		die()

func create_shield_break_effect():
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.spread = 180
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 200
	particles.color = Color(0, 0.5, 1)
	
	get_tree().current_scene.add_child(particles)
	
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(particles):
		particles.queue_free()

func die():
	# Explosion effect
	var explosion = CPUParticles2D.new()
	explosion.global_position = global_position
	explosion.emitting = true
	explosion.one_shot = true
	explosion.amount = 40
	explosion.lifetime = 0.6
	explosion.explosiveness = 0.8
	explosion.spread = 180
	explosion.initial_velocity_min = 150
	explosion.initial_velocity_max = 300
	explosion.scale_amount_min = 3
	explosion.scale_amount_max = 8
	
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(1, 0.5, 0, 1))
	gradient.add_point(0.5, Color(0.8, 0.3, 0, 0.8))
	gradient.add_point(1.0, Color(0.2, 0.1, 0, 0))
	explosion.color_ramp = gradient
	
	get_tree().current_scene.add_child(explosion)
	
	# Spawn coins
	var coin_scene = preload("res://rewards/coins/coin.tscn")
	for i in range(2):  # Drop 2 coins
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	
	if player and player.has_method("add_orcs_killed"):
		player.add_orcs_killed(1)
	
	died.emit()
	queue_free()
