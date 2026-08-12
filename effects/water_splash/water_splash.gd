extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

@export_range(0.1, 1.0, 0.05) var duration: float = 0.8


func _ready() -> void:
	sprite.modulate.a = 1.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "scale", Vector2(0.7, 0.45), duration)
	tween.tween_property(sprite, "position:y", -4.0, duration)
	tween.tween_property(sprite, "modulate:a", 0.0, duration)

	await tween.finished
	queue_free()
