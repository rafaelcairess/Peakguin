extends Node

signal second_changed(total_seconds: int)

const MAX_DISPLAY_SECONDS := 99 * 60 + 59

var elapsed_time := 0.0
var running := true

var _displayed_second := -1


func _process(delta: float) -> void:
	if not running:
		return

	elapsed_time += delta
	var current_second := mini(floori(elapsed_time), MAX_DISPLAY_SECONDS)

	if current_second == _displayed_second:
		return

	_displayed_second = current_second
	second_changed.emit(current_second)


func reset_run() -> void:
	elapsed_time = 0.0
	_displayed_second = -1
	running = true


func pause_run() -> void:
	running = false


func resume_run() -> void:
	running = true


func get_current_second() -> int:
	return mini(floori(elapsed_time), MAX_DISPLAY_SECONDS)
