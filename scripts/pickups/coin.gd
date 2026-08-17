extends "res://scripts/pickups/pickup.gd"

@export_category("Coleta")
@export_range(1, 99, 1) var value := 1

func collect(body: Node2D) -> bool:
	if not body.has_method("collect_coin"):
		return false

	body.collect_coin(value)
	return true


func is_persistently_collected(scene_path: String, item_id: String) -> bool:
	return SaveManager.is_coin_collected(scene_path, item_id)


func register_persistent_collection(scene_path: String, item_id: String) -> void:
	SaveManager.record_coin(scene_path, item_id)
