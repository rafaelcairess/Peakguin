extends "res://skeleton.gd"

func update_direction() -> void:
	var detection_distance := absf(player_detector.target_position.x)
	super.update_direction()
	player_detector.target_position.x = detection_distance * direction
