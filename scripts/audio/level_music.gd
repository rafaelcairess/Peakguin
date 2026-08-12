extends Node

@export_category("Música da fase")
@export var music: AudioStream
@export_range(0.0, 5.0, 0.1) var fade_duration: float = 1.0


func _ready() -> void:
	MusicManager.play_music(music, fade_duration)
