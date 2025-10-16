extends Area2D

@export var value: int = 1


func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.add_coins(value)
		queue_free()
