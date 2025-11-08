# weapon_base.gd
class_name WeaponBase
extends Node2D

# Stats that can be upgraded
@export var damage: float = 10.0
@export var attack_speed: float = 1.0  # attacks per second
@export var level: int = 1

var attack_timer: Timer
var player: CharacterBody2D

func _ready():
	# Get player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Setup attack timer
	attack_timer = Timer.new()
	add_child(attack_timer)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start(1.0 / attack_speed)

func _on_attack_timer_timeout():
	attack()

# Override this in child classes
func attack():
	pass

# Called when weapon levels up
func upgrade():
	level += 1
	apply_upgrade()

# Override this to define level-up behavior
func apply_upgrade():
	pass
