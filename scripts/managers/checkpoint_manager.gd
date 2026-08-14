extends Node

signal checkpoint_changed(scene_path: String, respawn_position: Vector2)

var active_scene_path: String = ""
var active_respawn_position: Vector2 = Vector2.ZERO
var has_active_checkpoint: bool = false


func activate_checkpoint(scene_path: String, respawn_position: Vector2) -> void:
	active_scene_path = scene_path
	active_respawn_position = respawn_position
	has_active_checkpoint = true
	checkpoint_changed.emit(active_scene_path, active_respawn_position)


func get_respawn_position(scene_path: String, default_position: Vector2) -> Vector2:
	if not has_active_checkpoint:
		return default_position
	if active_scene_path != scene_path:
		clear_checkpoint()
		return default_position
	return active_respawn_position


func is_active_checkpoint(scene_path: String, respawn_position: Vector2) -> bool:
	return (
		has_active_checkpoint
		and active_scene_path == scene_path
		and active_respawn_position.is_equal_approx(respawn_position)
	)


func clear_checkpoint() -> void:
	active_scene_path = ""
	active_respawn_position = Vector2.ZERO
	has_active_checkpoint = false
