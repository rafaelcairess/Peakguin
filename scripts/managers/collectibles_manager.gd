extends Node

## Persiste quais coletáveis já foram coletados por cena.
## Sobrevive a reloads (ex: morte do player), mas é separado por fase.

# Formato: { "res://scene/fase.tscn": ["CaminhoDoNo1", "CaminhoDoNo2", ...] }
var _collected: Dictionary = {}


func mark_collected(scene_path: String, item_id: String) -> void:
	if not _collected.has(scene_path):
		_collected[scene_path] = []

	var list: Array = _collected[scene_path]
	if not list.has(item_id):
		list.append(item_id)


func is_collected(scene_path: String, item_id: String) -> bool:
	if not _collected.has(scene_path):
		return false

	return item_id in _collected[scene_path]


func clear_scene(scene_path: String) -> void:
	_collected.erase(scene_path)


func clear_all() -> void:
	_collected.clear()
