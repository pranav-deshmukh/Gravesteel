extends CharacterBody2D

signal health_depleted
signal coin_collected(coins)

@export var move_speed: float = 300
@export var max_health: float = 100.0
@export var damage: float = 10.0
@export var attack_speed: float = 1.0
@export var world_size: Vector2 = Vector2(8000, 8000)

var health = max_health
@export var coins: int = 0
@export var orcs_killed = 0
var level_need_coins: int = 25
var kills_for_next_chest: int = 5

@onready var weapon_manager = $WeaponManager
@onready var coin_label = get_node("/root/Game/CoinsCollected/ColorRect/HBoxContainer/Label")
@onready var orcs_killed_label = get_node("/root/Game/Orcs_Killed/ColorRect/HBoxContainer/Label")
@onready var coin_collected_bar = get_node("/root/Game/gemcollected/ProgressBar")
@onready var game = get_tree().get_root().get_node("Game")
@onready var FloatingText = preload("res://floating_text.tscn")
@onready var chest_scene = preload("res://Chest/chest.tscn")
var upgrades = UpgradesData.upgrades

# Blood splatter effect variables
var blood_canvas: CanvasLayer
var blood_particles: CPUParticles2D
var is_taking_damage: bool = false


func _ready():
	add_to_group("player")
	
	# Setup blood splatter effect
	setup_blood_effect()
	
	# Start with orbit weapon
	var orbit_weapon = preload("res://Weapons/weapon-scenes/orbs/orbit_weapon.tscn")
	var lightning_weapon = preload("res://Weapons/weapon-scenes/Area_Weapons/Lightning_Strike/lightning_weapon.tscn")
	var bow_arrow = preload("res://Weapons/weapon-scenes/arrow/gun.tscn")
	var spear_thrower = preload("res://Weapons/Projectile_Weapons/Spear/spear_thrower.tscn")
	var dagger = preload("res://Weapons/Projectile_Weapons/Dagger/ricochet_dagger.tscn")
	var satellite_drones = preload("res://Weapons/weapon-scenes/Orbit_Weapon/satellite_drones.tscn")
	var magic_wand = preload("res://Weapons/Projectile_Weapons/magic_wand/arcane_conduit.tscn")
	var meteor_shower = preload("res://Weapons/weapon-scenes/Area_Weapons/meteor_shower/meteor_shower.tscn")
	var boomerang_blades = preload("res://Weapons/Projectile_Weapons/boomerang_blades/boomerang_blades.tscn")
	var fire_aura = preload("res://Weapons/weapon-scenes/Aura_Weapon/aura_weapon.tscn")
	weapon_manager.add_weapon(boomerang_blades)

func setup_blood_effect():
	# Create canvas layer for screen-space effects
	blood_canvas = CanvasLayer.new()
	blood_canvas.layer = 100  # Above everything else
	add_child(blood_canvas)
	
	# Create blood particles for splatter effect
	blood_particles = CPUParticles2D.new()
	blood_particles.emitting = false
	blood_particles.one_shot = false  # Continuous emission
	blood_particles.explosiveness = 0.7
	blood_particles.amount = 100
	blood_particles.lifetime = 0.4
	blood_particles.speed_scale = 1.5
	
	# Particle properties - smaller radius
	blood_particles.direction = Vector2(0, 1)
	blood_particles.spread = 180
	blood_particles.initial_velocity_min = 100
	blood_particles.initial_velocity_max = 200
	blood_particles.gravity = Vector2(0, 300)
	blood_particles.scale_amount_min = 2.0
	blood_particles.scale_amount_max = 5.0
	blood_particles.z_index=-10
	
	# Color and appearance
	var gradient = Gradient.new()
	gradient.add_point(0.0, Color(0.9, 0.1, 0.1, 1))    # Bright red
	gradient.add_point(0.5, Color(0.7, 0, 0, 0.8))      # Dark red
	gradient.add_point(1.0, Color(0.4, 0.0, 0.0, 0.659))        # Fade out
	blood_particles.color_ramp = gradient
	
	blood_canvas.add_child(blood_particles)

func _physics_process(delta):
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position.x = clamp(position.x, -world_size.x/2, world_size.x/2)
	position.y = clamp(position.y, -world_size.y/2, world_size.y/2)
	velocity = direction * move_speed
	move_and_slide()
	
	if direction.x > 0:
		%maincharacter.flip_horizontal(false)
	elif direction.x < 0:
		%maincharacter.flip_horizontal(true)
	
	if velocity.length() > 0.0:
		%maincharacter.play_walk_animation()
	else:
		%maincharacter.play_idle_animation()
	
	# Taking damage
	const DAMAGE_RATE = 6.0
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		shake_camera(30)
		
		# Trigger blood splatter effect - keep spraying while taking damage
		if not is_taking_damage:
			is_taking_damage = true
			trigger_blood_effect()
		
		%HealthBar.value = health
		if health <= 0.0:
			health_depleted.emit()
	else:
		# Stop blood spray when no longer taking damage
		if is_taking_damage:
			is_taking_damage = false
			stop_blood_effect()

func trigger_blood_effect():
	# Position particles at screen center
	var viewport_size = get_viewport_rect().size
	blood_particles.position = viewport_size / 2
	
	# Start continuous blood splatter
	blood_particles.emitting = true

func stop_blood_effect():
	# Stop emitting particles
	blood_particles.emitting = false

func add_coins(value):
	coins += value
	coin_label.text = str(coins) + " coins"
	coin_collected_bar.value = (coins * 100) / level_need_coins
	add_floating_text("+1")
	
	# Check if we've reached the threshold
	if coins >= level_need_coins:
		trigger_level_up()

func add_orcs_killed(value):
	orcs_killed+=value
	orcs_killed_label.text = str(orcs_killed) + " orcs"
	if orcs_killed>=kills_for_next_chest:
		spawn_chest()
		kills_for_next_chest += 20

func spawn_chest():
	if chest_scene:
		var chest = chest_scene.instantiate()
		get_parent().add_child(chest)
		var offset = Vector2(randf_range(-200,200), randf_range(-200,200))
		chest.global_position = global_position + offset
	else:
		push_error("Chest scene not found! Check the path.")

func trigger_level_up():
	coins = 0
	coin_label.text = "0 coins"
	coin_collected_bar.value = 0
	
	# Show upgrade menu
	var upgrade_menu = get_node("/root/Game/UpgradeMenu/UpgradeMenu")
	if upgrade_menu:
		upgrade_menu.show_upgrades(upgrades)
	else:
		push_error("UpgradeMenu not found!")

func add_floating_text(val: String):
	var popup = FloatingText.instantiate()
	popup.text = val
	popup.position = position + Vector2(0, -40)
	get_tree().current_scene.add_child(popup)

func shake_camera(intensity: float = 5.0):
	var camera = get_viewport().get_camera_2d()
	var tween = create_tween()
	tween.tween_property(camera, "offset", 
		Vector2(randf_range(-intensity, intensity), 
				randf_range(-intensity, intensity)), 0.1)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.1)
