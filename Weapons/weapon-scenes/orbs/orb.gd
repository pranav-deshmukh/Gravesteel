# orb.gd
extends Area2D

var damage: float = 10.0
var hit_cooldown: Dictionary = {}  # enemy: time_last_hit

func _ready():
	#print("Orb ready at ", position)
	body_entered.connect(_on_body_entered)

func _process(delta):
	# Clean up old cooldowns
	for enemy in hit_cooldown.keys():
		if not is_instance_valid(enemy):
			hit_cooldown.erase(enemy)

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		# Cooldown to prevent hitting same enemy multiple times per second
		if body in hit_cooldown:
			if Time.get_ticks_msec() - hit_cooldown[body] < 500:  # 0.5 sec cooldown
				return
		
		if body.has_method("take_damage"):
			body.take_damage(damage)
			hit_cooldown[body] = Time.get_ticks_msec()
