class_name LightningWeapon
extends WeaponBase

@export var area_radius: float = 150.0
@export var strike_count: int = 1
@export var chain_count: int = 0

func _ready():
	super._ready()
	#print("LightningWeapon ready!")

func attack():
	#print("Lightning attacking! Strikes: ", strike_count)
	for i in range(strike_count):
		spawn_lightning_strike()

func spawn_lightning_strike():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		#print("No enemies to strike")
		return
	
	var target = enemies[randi() % enemies.size()]
	var strike_position = target.global_position
	
	#print("Lightning targeting enemy at: ", strike_position)
	
	spawn_warning_indicator(strike_position)
	await get_tree().create_timer(0.3).timeout
	deal_area_damage(strike_position)
	spawn_explosion_effect(strike_position)
	
	if player and player.has_method("shake_camera"):
		player.shake_camera(15)

func spawn_warning_indicator(pos: Vector2):
	var warning = ColorRect.new()
	warning.color = Color(1, 1, 0, 0.5)
	warning.size = Vector2(area_radius * 2, area_radius * 2)
	warning.position = pos - warning.size / 2
	get_tree().root.add_child(warning)
	
	var tween = create_tween()
	tween.tween_property(warning, "modulate:a", 0.0, 0.3)
	tween.tween_callback(warning.queue_free)

func deal_area_damage(pos: Vector2):
	var area = Area2D.new()
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = area_radius
	
	shape.shape = circle
	area.add_child(shape)
	area.global_position = pos
	area.collision_mask = 2
	
	get_tree().root.add_child(area)
	await get_tree().physics_frame
	
	var hit_enemies = area.get_overlapping_bodies()
	#print("Lightning hit ", hit_enemies.size(), " enemies")
	
	for enemy in hit_enemies:
		if enemy.is_in_group("enemies") and enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			#print("Damaged enemy: ", enemy.name)
	
	area.queue_free()

func spawn_explosion_effect(pos: Vector2):
	var flash = ColorRect.new()
	flash.color = Color(0.5, 0.5, 1, 0.8)
	flash.size = Vector2(area_radius * 2, area_radius * 2)
	flash.position = pos - flash.size / 2
	get_tree().root.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.2)
	tween.tween_callback(flash.queue_free)

func apply_upgrade():
	match level:
		2:
			area_radius *= 1.3
			#print("Lightning: +30% radius")
		3:
			damage *= 1.5
			#print("Lightning: +50% damage")
		4:
			strike_count = 2
			#print("Lightning: 2 strikes")
		5:
			damage *= 2.0
			#print("Lightning: +100% damage")
		6:
			strike_count = 3
			attack_speed *= 1.5
			attack_timer.wait_time = 1.0 / attack_speed
			#print("Lightning: 3 strikes, faster")
