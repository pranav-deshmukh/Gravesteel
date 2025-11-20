extends ColorRect

@onready var slot1 = $WeaponSlot1/Icon
@onready var slot2 = $WeaponSlot2/Icon
@onready var slot3 = $WeaponSlot3/Icon
@onready var slot4 = $WeaponSlot4/Icon
@onready var slot5 = $WeaponSlot5/Icon
@onready var slot6 = $WeaponSlot6/Icon

var slots: Array[TextureRect] = []
var slot_filled: Array[bool] = [false, false, false, false, false, false]
var slot_weapons: Array[String] = ["", "", "", "", "", ""]  # Track weapon names
var weapon_icons: Dictionary = {}

func _ready():
	# Store all slots in array
	slots = [slot1, slot2, slot3, slot4, slot5, slot6]
	
	# Load weapon icons
	load_weapon_icons()

func load_weapon_icons():
	weapon_icons = {
		"ProjectileWeapon": preload("res://pistol/projectile.png"),
		"orbit_weapon": preload("res://pistol/projectile.png"),
		"lightning_weapon": preload("res://pistol/projectile.png"),
		"aura_weapon": preload("res://pistol/projectile.png"),
		# Add more weapons as needed
	}

func add_weapon(weapon_name: String) -> bool:
	# Find first empty slot
	for i in range(slots.size()):
		if not slot_filled[i]:
			fill_slot(i, weapon_name)
			print("Weapon added to slot ", i + 1, ": ", weapon_name)
			return true
	
	print("Warning: All weapon slots full!")
	return false

func fill_slot(slot_index: int, weapon_name: String):
	# Set icon texture
	if weapon_icons.has(weapon_name):
		slots[slot_index].texture = weapon_icons[weapon_name]
	else:
		# Fallback: use a default texture or colored rect
		print("Warning: No icon for weapon: ", weapon_name)
	
	# Mark slot as filled and store weapon name
	slot_filled[slot_index] = true
	slot_weapons[slot_index] = weapon_name

func remove_weapon(slot_index: int):
	if slot_index < 0 or slot_index >= slots.size():
		print("Error: Invalid slot index")
		return
	
	# Clear the slot
	slots[slot_index].texture = null
	slot_filled[slot_index] = false
	slot_weapons[slot_index] = ""
	print("Weapon removed from slot ", slot_index + 1)

func remove_weapon_by_name(weapon_name: String) -> bool:
	# Find and remove weapon by name
	for i in range(slot_weapons.size()):
		if slot_weapons[i] == weapon_name:
			remove_weapon(i)
			return true
	
	print("Weapon not found: ", weapon_name)
	return false

func is_slot_empty(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	return not slot_filled[slot_index]

func has_weapon(weapon_name: String) -> bool:
	return weapon_name in slot_weapons

func get_weapon_count() -> int:
	var count = 0
	for filled in slot_filled:
		if filled:
			count += 1
	return count

func get_all_weapons() -> Array[String]:
	var weapons: Array[String] = []
	for weapon in slot_weapons:
		if weapon != "":
			weapons.append(weapon)
	return weapons

func clear_all_slots():
	for i in range(slots.size()):
		remove_weapon(i)
	print("All weapon slots cleared")
