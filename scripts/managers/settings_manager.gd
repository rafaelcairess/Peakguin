extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const MIN_VOLUME_DB := -80.0
const DEFAULT_FOOTSTEP_CUTOFF_SECONDS := 0.12
const MIN_FOOTSTEP_CUTOFF_SECONDS := 0.03
const MAX_FOOTSTEP_CUTOFF_SECONDS := 2.02

const MASTER_BUS := &"Master"
const MUSIC_BUS := &"Music"
const SFX_BUS := &"SFX"
const PLAYER_JUMP_BUS := &"PlayerJump"
const PLAYER_STEPS_BUS := &"PlayerSteps"

var master_volume := 100.0
var music_volume := 100.0
var sfx_volume := 100.0
var jump_volume := 100.0
var steps_volume := 100.0
var footstep_cutoff_seconds := DEFAULT_FOOTSTEP_CUTOFF_SECONDS
var fullscreen := false
var resolution := WindowManager.DEFAULT_WINDOW_SIZE


func _ready() -> void:
	load_settings()
	apply_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var loaded := config.load(SETTINGS_PATH) == OK

	master_volume = _read_volume(config, loaded, "master", MASTER_BUS)
	music_volume = _read_volume(config, loaded, "music", MUSIC_BUS)
	sfx_volume = _read_volume(config, loaded, "sfx", SFX_BUS)
	jump_volume = _read_volume(config, loaded, "player_jump", PLAYER_JUMP_BUS)
	steps_volume = _read_volume(config, loaded, "player_steps", PLAYER_STEPS_BUS)
	footstep_cutoff_seconds = clampf(
		float(config.get_value(
			"audio",
			"footstep_cutoff_seconds",
			DEFAULT_FOOTSTEP_CUTOFF_SECONDS
		)) if loaded else DEFAULT_FOOTSTEP_CUTOFF_SECONDS,
		MIN_FOOTSTEP_CUTOFF_SECONDS,
		MAX_FOOTSTEP_CUTOFF_SECONDS
	)
	fullscreen = bool(config.get_value(
		"video", "fullscreen", _is_fullscreen()
	)) if loaded else _is_fullscreen()
	resolution = Vector2i(
		int(config.get_value(
			"video", "resolution_width", WindowManager.DEFAULT_WINDOW_SIZE.x
		)) if loaded else WindowManager.DEFAULT_WINDOW_SIZE.x,
		int(config.get_value(
			"video", "resolution_height", WindowManager.DEFAULT_WINDOW_SIZE.y
		)) if loaded else WindowManager.DEFAULT_WINDOW_SIZE.y
	)
	if resolution not in WindowManager.RESOLUTIONS:
		resolution = WindowManager.DEFAULT_WINDOW_SIZE


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("audio", "player_jump", jump_volume)
	config.set_value("audio", "player_steps", steps_volume)
	config.set_value("audio", "footstep_cutoff_seconds", footstep_cutoff_seconds)
	config.set_value("video", "fullscreen", fullscreen)
	config.set_value("video", "resolution_width", resolution.x)
	config.set_value("video", "resolution_height", resolution.y)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Não foi possível salvar as configurações: " + error_string(error))


func apply_settings() -> void:
	_apply_bus_volume(MASTER_BUS, master_volume)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	_apply_bus_volume(PLAYER_JUMP_BUS, jump_volume)
	_apply_bus_volume(PLAYER_STEPS_BUS, steps_volume)
	WindowManager.set_resolution(resolution)
	WindowManager.set_fullscreen(fullscreen)
	settings_changed.emit()


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 100.0)
	_apply_bus_volume(MASTER_BUS, master_volume)
	settings_changed.emit()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 100.0)
	_apply_bus_volume(MUSIC_BUS, music_volume)
	settings_changed.emit()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 100.0)
	_apply_bus_volume(SFX_BUS, sfx_volume)
	settings_changed.emit()


func set_jump_volume(value: float) -> void:
	jump_volume = clampf(value, 0.0, 100.0)
	_apply_bus_volume(PLAYER_JUMP_BUS, jump_volume)
	settings_changed.emit()


func set_steps_volume(value: float) -> void:
	steps_volume = clampf(value, 0.0, 100.0)
	_apply_bus_volume(PLAYER_STEPS_BUS, steps_volume)
	settings_changed.emit()


func set_footstep_cutoff(value: float) -> void:
	footstep_cutoff_seconds = clampf(
		value,
		MIN_FOOTSTEP_CUTOFF_SECONDS,
		MAX_FOOTSTEP_CUTOFF_SECONDS
	)
	settings_changed.emit()


func set_video(value_resolution: Vector2i, value_fullscreen: bool) -> void:
	resolution = value_resolution \
		if value_resolution in WindowManager.RESOLUTIONS \
		else WindowManager.DEFAULT_WINDOW_SIZE
	fullscreen = value_fullscreen
	WindowManager.set_resolution(resolution)
	WindowManager.set_fullscreen(fullscreen)
	settings_changed.emit()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	WindowManager.set_fullscreen(fullscreen)
	settings_changed.emit()


func _read_volume(
	config: ConfigFile,
	loaded: bool,
	key: String,
	bus_name: StringName
) -> float:
	var fallback := _get_bus_percent(bus_name)
	return clampf(
		float(config.get_value("audio", key, fallback)) if loaded else fallback,
		0.0,
		100.0
	)


func _apply_bus_volume(bus_name: StringName, percent: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Bus de áudio não encontrado: " + String(bus_name))
		return

	var normalized := clampf(percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, is_zero_approx(normalized))
	AudioServer.set_bus_volume_db(
		bus_index,
		MIN_VOLUME_DB if is_zero_approx(normalized) else linear_to_db(normalized)
	)


func _get_bus_percent(bus_name: StringName) -> float:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1 or AudioServer.is_bus_mute(bus_index):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(bus_index)) * 100.0


func _is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN \
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
