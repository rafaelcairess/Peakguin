extends "res://scripts/pickups/pickup.gd"

@export_category("Coleta")
@export_range(1, 3, 1) var healing := 1

func collect(body: Node2D) -> bool:
	if not body.has_method("collect_heart"):
		return false

	return body.collect_heart(healing)
