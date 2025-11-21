extends CharacterBody2D

signal health_depleted
signal coin_collected(coins)

@export var move_speed: float = 400
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


func _ready():
	add_to_group("player")  # ← Important for weapons to find player!
	
	# Start with orbit weapon
	var orbit_weapon = preload("res://Weapons/weapon-scenes/orbs/orbit_weapon.tscn")
	var lightning_weapon = preload("res://Weapons/weapon-scenes/Area_Weapons/Lightning_Strike/lightning_weapon.tscn")
	var bow_arrow = preload("res://Weapons/weapon-scenes/arrow/gun.tscn")
	weapon_manager.add_weapon(bow_arrow)

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
		%HealthBar.value = health
		if health <= 0.0:
			health_depleted.emit()

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
	#print("=== SPAWNING CHEST at ", orcs_killed, " kills ===")
	if chest_scene:
		var chest = chest_scene.instantiate()
		get_parent().add_child(chest)
		var offset = Vector2(randf_range(-200,200), randf_range(-200,200))
		chest.global_position = global_position + offset
		#print("Chest spawned at: ", chest.global_position)
	else:
		push_error("Chest scene not found! Check the path.")

func trigger_level_up():
	#print("=== LEVEL UP ===")
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
