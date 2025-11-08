extends Area2D

@export var chest_type: String = "normal"  # normal, rare, epic
@export var one_time_use: bool = true

var is_open: bool = false
var player_nearby: bool = false
var nearby_player = null

@onready var prompt_label = $PromptLabel if has_node("PromptLabel") else null

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Hide prompt initially
	if prompt_label:
		prompt_label.visible = false

func _process(_delta):
	# Check for interact input while player is nearby
	if player_nearby and not is_open and Input.is_action_just_pressed("interact"):
		open_chest()

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_nearby = true
		nearby_player = body
		show_prompt()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_nearby = false
		nearby_player = null
		hide_prompt()

func open_chest():
	if is_open:
		return
	
	is_open = true
	#print("Chest opened!")
	
	# Hide prompt
	hide_prompt()
	
	# Play opening animation/sound
	play_open_animation()
	
	# Show upgrade menu
	show_upgrade_menu()
	
	# Destroy chest after menu closes (optional)
	if one_time_use:
		# Wait a bit so player sees chest open
		await get_tree().create_timer(0.5).timeout
		queue_free()

func show_upgrade_menu():
	# Get the upgrade menu
	var upgrade_menu = get_node("/root/Game/UpgradeMenu/UpgradeMenu")
	
	if upgrade_menu:
		upgrade_menu.show_upgrades_from_weapon_manager()
	else:
		push_error("UpgradeMenu not found!")

func play_open_animation():
	if has_node("AnimatedSprite2D"):
		var sprite = $AnimatedSprite2D
		
		# Check if the "open" animation exists
		if "open" in sprite.sprite_frames.get_animation_names():
			sprite.play("open")
			#print("open animation played")
		else:
			print("No 'open' animation found in AnimatedSprite2D!")
			
	elif has_node("Sprite2D"):
		# fallback for non-animated sprite
		$Sprite2D.modulate = Color(0.8, 0.8, 0.8)


func show_prompt():
	if prompt_label:
		prompt_label.text = "Press E"
		prompt_label.visible = true

func hide_prompt():
	if prompt_label:
		prompt_label.visible = false

#func spawn_chest():
	#print("spawn chest")
