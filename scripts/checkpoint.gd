extends Area2D

@export var inactive_color: Color = Color.WHITE
@export var active_color: Color = Color(0.45, 1.0, 0.55, 1.0)

@onready var sign_sprite: Sprite2D = $Sign
@onready var respawn_position: Marker2D = $RespawnPosition


func _ready() -> void:
	CheckpointManager.checkpoint_changed.connect(_on_checkpoint_changed)
	refresh_visual()


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return

	CheckpointManager.activate_checkpoint(
		get_scene_path(),
		respawn_position.global_position
	)


func _on_checkpoint_changed(_scene_path: String, _position: Vector2) -> void:
	refresh_visual()


func refresh_visual() -> void:
	if CheckpointManager.is_active_checkpoint(
		get_scene_path(),
		respawn_position.global_position
	):
		sign_sprite.modulate = active_color
	else:
		sign_sprite.modulate = inactive_color


func get_scene_path() -> String:
	var current_scene := get_tree().current_scene

	if current_scene == null:
		return ""

	return current_scene.scene_file_path
