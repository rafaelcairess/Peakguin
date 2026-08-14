extends Camera2D

var target: Node2D
var shake_intensity: float = 0.0
var shake_duration: float = 0.0


func _ready() -> void:
	get_target()


func _process(delta: float) -> void:
	if target != null:
		global_position = target.global_position
		
		if shake_duration > 0:
			shake_duration -= delta
			global_position += Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			if shake_duration <= 0:
				shake_intensity = 0.0
				global_position = target.global_position


func apply_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration


func get_target() -> void:
	var nodes = get_tree().get_nodes_in_group("Player")

	if nodes.size() == 0:
		push_error("Player not found")
		return

	target = nodes[0]
