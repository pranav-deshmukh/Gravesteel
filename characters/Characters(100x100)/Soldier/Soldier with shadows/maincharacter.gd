extends Node2D


func play_idle_animation():
	%AnimatedSprite2D.play("idle")


func play_walk_animation():
	%AnimatedSprite2D.play("walk")

func flip_horizontal(value):
	$AnimatedSprite2D.flip_h = value	
