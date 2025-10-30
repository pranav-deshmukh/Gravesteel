extends Label

func _ready() -> void:
	animate()

func animate():
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 30, 0.5) # move up
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)  # fade out
	tween.tween_callback(Callable(self, "queue_free"))             # delete after
