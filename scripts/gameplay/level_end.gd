extends Area2D

@export var next_level = ""


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	call_deferred("load_next_scene")


func load_next_scene() -> void:
	var current_scene := get_tree().current_scene
	var next_scene_path: String = "res://scene/" + next_level + ".tscn"
	if current_scene != null:
		SaveManager.complete_level(current_scene.scene_file_path, next_scene_path)
	get_tree().change_scene_to_file(next_scene_path)
