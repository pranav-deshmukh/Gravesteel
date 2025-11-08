class_name OrbitWeapon
extends WeaponBase

@export var orb_scene: PackedScene
@export var orbit_radius: float = 120.0
@export var orbit_speed: float = 0.5  # rotations per second
@export var orb_count: int = 1

var orbs: Array = []

func _ready():
	super._ready()
	spawn_orbs()
	
func spawn_orbs():
	for orb in orbs:
		if is_instance_valid(orb):
			orb.queue_free()
	orbs.clear()

	for i in range(orb_count):
		var orb = orb_scene.instantiate()
		add_child(orb)

		var angle = (TAU / orb_count) * i
		orb.position = Vector2(cos(angle), sin(angle)) * orbit_radius
		orb.damage = damage
		orbs.append(orb)

		
func _process(delta: float) -> void:
	if player and is_instance_valid(player):
		global_position = player.global_position  # follow player
	rotation += orbit_speed * TAU * delta  # spin orbs


func attack():
	# Orbit weapons don't use timer-based attacks
	# They deal damage on contact
	pass

func apply_upgrade():
	match level:
		2:
			orb_count = 2
			spawn_orbs()
			#print("Orbit upgraded: +1 orb")
		3:
			damage *= 1.5
			for orb in orbs:
				orb.damage = damage
			#print("Orbit upgraded: +50% damage")
		4:
			orb_count = 3
			spawn_orbs()
			#print("Orbit upgraded: +1 orb (3 total)")
		5:
			orbit_radius *= 1.3
			spawn_orbs()
			#print("Orbit upgraded: +30% radius")
		6:
			orb_count = 4
			orbit_speed *= 1.5
			spawn_orbs()
			#print("Orbit upgraded: +1 orb, faster spin")
		7:
			orb_count = 5
			orbit_speed *= 1.5
			spawn_orbs()
			#print("Orbit upgraded: +1 orb, faster spin")
		8:
			orb_count = 6
			orbit_speed *= 1.5
			spawn_orbs()
			#print("Orbit upgraded: +1 orb, faster spin")
