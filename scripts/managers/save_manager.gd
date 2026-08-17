extends Node

signal progress_changed

const SAVE_PATH := "user://progress.cfg"
const AUTOSAVE_INTERVAL := 10.0
const LEVEL_PATHS: Array[String] = [
	"res://scene/grassland.tscn",
	"res://scene/winter.tscn",
	"res://scene/tropic.tscn",
	"res://scene/forest.tscn",
]
const LEVEL_NAMES := {
	"res://scene/grassland.tscn": "Tutorial",
	"res://scene/winter.tscn": "Inverno",
	"res://scene/tropic.tscn": "Trópicos",
	"res://scene/forest.tscn": "Floresta",
}

var levels: Dictionary = {}
var total_play_time := 0.0
var last_level_path := ""

var _active_level_path := ""
var _current_attempt_time := 0.0
var _autosave_elapsed := 0.0


func _ready() -> void:
	load_progress()


func _process(delta: float) -> void:
	if _active_level_path.is_empty() or not RunTimer.running:
		return

	total_play_time += delta
	_current_attempt_time += delta
	var stats := _get_or_create_stats(_active_level_path)
	stats["play_time"] = float(stats.get("play_time", 0.0)) + delta
	levels[_active_level_path] = stats

	_autosave_elapsed += delta
	if _autosave_elapsed >= AUTOSAVE_INTERVAL:
		_autosave_elapsed = 0.0
		save_progress()


func begin_level(scene_path: String, total_coins: int) -> void:
	if scene_path not in LEVEL_PATHS:
		return

	if _active_level_path != scene_path:
		_active_level_path = scene_path
		_current_attempt_time = 0.0

	last_level_path = scene_path
	var stats := _get_or_create_stats(scene_path)
	stats["total_coins"] = maxi(int(stats.get("total_coins", 0)), total_coins)
	levels[scene_path] = stats
	save_progress()
	progress_changed.emit()


func stop_tracking() -> void:
	if not _active_level_path.is_empty():
		save_progress()
	_active_level_path = ""
	_current_attempt_time = 0.0
	_autosave_elapsed = 0.0


func record_coin(scene_path: String, item_id: String) -> void:
	if scene_path not in LEVEL_PATHS or item_id.is_empty():
		return

	var stats := _get_or_create_stats(scene_path)
	var collected_coins: Array = stats.get("coins", [])
	if item_id in collected_coins:
		return

	collected_coins.append(item_id)
	stats["coins"] = collected_coins
	levels[scene_path] = stats
	save_progress()
	progress_changed.emit()


func is_coin_collected(scene_path: String, item_id: String) -> bool:
	var stats := _get_or_create_stats(scene_path)
	var collected_coins: Array = stats.get("coins", [])
	return item_id in collected_coins


func record_death(scene_path: String) -> void:
	if scene_path not in LEVEL_PATHS:
		return

	var stats := _get_or_create_stats(scene_path)
	stats["deaths"] = int(stats.get("deaths", 0)) + 1
	levels[scene_path] = stats
	save_progress()
	progress_changed.emit()


func complete_level(scene_path: String, next_scene_path: String) -> void:
	if scene_path not in LEVEL_PATHS:
		return

	var stats := _get_or_create_stats(scene_path)
	stats["completed"] = true
	var previous_best := float(stats.get("best_time", 0.0))
	if _current_attempt_time > 0.0 and (
		previous_best <= 0.0 or _current_attempt_time < previous_best
	):
		stats["best_time"] = _current_attempt_time
	levels[scene_path] = stats

	if next_scene_path in LEVEL_PATHS:
		last_level_path = next_scene_path
	_active_level_path = ""
	_current_attempt_time = 0.0
	_autosave_elapsed = 0.0
	save_progress()
	progress_changed.emit()


func get_level_stats(scene_path: String) -> Dictionary:
	return _get_or_create_stats(scene_path).duplicate(true)


func get_collected_coin_count(scene_path: String) -> int:
	var stats := _get_or_create_stats(scene_path)
	var collected_coins: Array = stats.get("coins", [])
	return collected_coins.size()


func get_total_deaths() -> int:
	var total := 0
	for scene_path in LEVEL_PATHS:
		total += int(_get_or_create_stats(scene_path).get("deaths", 0))
	return total


func get_total_collected_coins() -> int:
	var total := 0
	for scene_path in LEVEL_PATHS:
		total += get_collected_coin_count(scene_path)
	return total


func get_total_available_coins() -> int:
	var total := 0
	for scene_path in LEVEL_PATHS:
		total += int(_get_or_create_stats(scene_path).get("total_coins", 0))
	return total


func get_completed_level_count() -> int:
	var total := 0
	for scene_path in LEVEL_PATHS:
		if bool(_get_or_create_stats(scene_path).get("completed", false)):
			total += 1
	return total


func has_progress() -> bool:
	return (
		not last_level_path.is_empty()
		or get_total_deaths() > 0
		or get_total_collected_coins() > 0
		or get_completed_level_count() > 0
	)


func save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "levels", levels)
	config.set_value("progress", "total_play_time", total_play_time)
	config.set_value("progress", "last_level_path", last_level_path)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Não foi possível salvar o progresso: " + error_string(error))


func load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		levels = config.get_value("progress", "levels", {})
		total_play_time = maxf(float(config.get_value(
			"progress", "total_play_time", 0.0
		)), 0.0)
		last_level_path = String(config.get_value(
			"progress", "last_level_path", ""
		))

	for scene_path in LEVEL_PATHS:
		_get_or_create_stats(scene_path)
	if last_level_path not in LEVEL_PATHS:
		last_level_path = ""


func clear_progress() -> void:
	levels.clear()
	total_play_time = 0.0
	last_level_path = ""
	_active_level_path = ""
	_current_attempt_time = 0.0
	_autosave_elapsed = 0.0
	for scene_path in LEVEL_PATHS:
		_get_or_create_stats(scene_path)
	save_progress()
	progress_changed.emit()


func _get_or_create_stats(scene_path: String) -> Dictionary:
	if not levels.has(scene_path) or not levels[scene_path] is Dictionary:
		levels[scene_path] = _default_stats()

	var stats: Dictionary = levels[scene_path]
	for key in _default_stats():
		if not stats.has(key):
			stats[key] = _default_stats()[key]
	levels[scene_path] = stats
	return stats


func _default_stats() -> Dictionary:
	return {
		"completed": false,
		"coins": [],
		"total_coins": 0,
		"deaths": 0,
		"play_time": 0.0,
		"best_time": 0.0,
	}
