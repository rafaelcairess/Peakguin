extends "res://scripts/pickups/pickup.gd"

@export_category("Coleta")
@export_range(1, 99, 1) var value := 1

func collect(body: Node2D) -> bool:
	if not body.has_method("collect_coin"):
		return false

	body.collect_coin(value)
	return true
