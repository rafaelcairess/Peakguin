extends Node

@export_category("Música da fase")
@export var music: AudioStream
@export_range(0.0, 5.0, 0.1) var fade_duration: float = 1.0
@export var loop_music := true


func _ready() -> void:
	RunTimer.resume_run()
	var current_scene := get_tree().current_scene
	if current_scene != null:
		SaveManager.begin_level(
			current_scene.scene_file_path,
			get_tree().get_nodes_in_group("Coins").size()
		)
	if loop_music:
		_enable_loop(music)
	MusicManager.play_music(music, fade_duration)


func _enable_loop(stream: AudioStream) -> void:
	if stream == null:
		return
	for property in stream.get_property_list():
		if property.name == &"loop":
			stream.set(&"loop", true)
			return
