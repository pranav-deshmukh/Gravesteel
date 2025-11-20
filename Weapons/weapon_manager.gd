# weapon_manager.gd
extends Node


@export var available_weapons: Array[PackedScene] = []

var active_weapons: Array = []
var max_weapons: int = 6

@onready var weapon_display = get_tree().root.get_node("Game/HUD/ColorRect")

func _ready():
	if not weapon_display:
		push_error("WeaponDisplay not found!")
		
func add_weapon(weapon_scene: PackedScene):
	if active_weapons.size() >= max_weapons:
		push_error("Max weapons reached!")
		return
	
	var weapon = weapon_scene.instantiate()
	add_child(weapon)
	active_weapons.append(weapon)
	
	if weapon_display:
		var weapon_name = get_weapon_class_name(weapon)
		weapon_display.add_weapon(weapon_name)
	
	print("Added weapon: ", weapon.name)
	#print("Added weapon: ", weapon.name)
func get_weapon_class_name(weapon) -> String:
	# Get the actual class name
	if weapon.get_script():
		var script_path = weapon.get_script().resource_path
		var file_name = script_path.get_file().get_basename()
		return file_name
	return weapon.get_class()
	
func upgrade_weapon(weapon_name: String):
	for weapon in active_weapons:
		if weapon.name == weapon_name:
			weapon.upgrade()
			return
	
	push_error("Weapon not found: ", weapon_name)

func get_random_upgrade_options() -> Array:
	var options = []
	
	# Option 1: Add new weapon if possible
	if active_weapons.size() < max_weapons and available_weapons.size() > 0:
		var available = available_weapons.filter(func(w): 
			return not active_weapons.any(func(aw): return aw.scene_file_path == w.resource_path)
		)
		if available.size() > 0:
			options.append({
				"type": "new_weapon",
				"name": "New Weapon: " + available[0].resource_path.get_file().get_basename(),
				"weapon": available[0]
			})
	
	# Option 2-3: Upgrade existing weapons
	for weapon in active_weapons:
		if weapon.level < 6:  # Max level
			options.append({
				"type": "upgrade",
				"name": weapon.name + " Level " + str(weapon.level + 1),
				"weapon": weapon
			})
	
	# Shuffle and return 3 options
	options.shuffle()
	return options.slice(0, 3)
