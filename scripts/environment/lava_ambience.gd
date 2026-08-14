@tool
extends Node2D

## Fonte de som espacial reutilizável para poças de lava.
## O círculo desenhado no editor mostra até onde o som pode ser ouvido.

@export_range(32.0, 512.0, 1.0, "suffix:px") var audible_distance: float = 180.0:
	set(value):
		audible_distance = value
		_apply_audio_settings()
		queue_redraw()

@export_range(-40.0, 0.0, 1.0, "suffix:dB") var source_volume_db: float = -12.0:
	set(value):
		source_volume_db = value
		_apply_audio_settings()

@export_range(0.1, 4.0, 0.1) var attenuation: float = 1.5:
	set(value):
		attenuation = value
		_apply_audio_settings()

@export var show_range_in_editor: bool = true:
	set(value):
		show_range_in_editor = value
		queue_redraw()


func _ready() -> void:
	_apply_audio_settings()
	queue_redraw()


func _apply_audio_settings() -> void:
	var lava_loop := get_node_or_null("LavaLoop") as AudioStreamPlayer2D
	if lava_loop == null:
		return

	lava_loop.max_distance = audible_distance
	lava_loop.volume_db = source_volume_db
	lava_loop.attenuation = attenuation


func _draw() -> void:
	if not Engine.is_editor_hint() or not show_range_in_editor:
		return

	draw_arc(
		Vector2.ZERO,
		audible_distance,
		0.0,
		TAU,
		64,
		Color(1.0, 0.28, 0.08, 0.45),
		1.0
	)
