extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func set_direction(run_direction: float) -> void:
	if sprite == null:
		sprite = $AnimatedSprite2D
	if sprite != null:
		sprite.flip_h = run_direction < 0.0


func _on_animation_finished() -> void:
	queue_free()
