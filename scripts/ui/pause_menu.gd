extends CanvasLayer

## Menu de pausa global.
## A cena fica registrada como Autoload e, por isso, funciona em todas as fases.

const SETTINGS_PATH := "user://settings.cfg"
const MIN_VOLUME_DB := -80.0

@export_category("Arte opcional")
@export var panel_texture: Texture2D
@export var title_icon: Texture2D
@export var continue_icon: Texture2D
@export var options_icon: Texture2D
@export var quit_icon: Texture2D
@export var back_icon: Texture2D

@onready var overlay: Control = $Overlay
@onready var panel_sprite_slot: TextureRect = %PanelSpriteSlot
@onready var title_icon_slot: TextureRect = %TitleIconSlot
@onready var main_screen: VBoxContainer = %MainScreen
@onready var options_screen: VBoxContainer = %OptionsScreen
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var back_button: Button = %BackButton
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle

var _updating_controls := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_optional_art()
	overlay.hide()
	_load_settings()
	_show_main_screen()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	if not event.is_action_pressed("ui_cancel"):
		return

	if not overlay.visible:
		open_menu()
	elif options_screen.visible:
		_show_main_screen()
	else:
		close_menu()

	get_viewport().set_input_as_handled()


func open_menu() -> void:
	get_tree().paused = true
	overlay.show()
	_show_main_screen()
	continue_button.grab_focus()


func close_menu() -> void:
	overlay.hide()
	get_tree().paused = false


func _show_main_screen() -> void:
	main_screen.show()
	options_screen.hide()
	if overlay.visible:
		continue_button.grab_focus()


func _show_options_screen() -> void:
	main_screen.hide()
	options_screen.show()
	master_slider.grab_focus()


func _on_continue_pressed() -> void:
	close_menu()


func _on_options_pressed() -> void:
	_show_options_screen()


func _on_back_pressed() -> void:
	_show_main_screen()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()


func _on_master_volume_changed(value: float) -> void:
	_set_bus_volume(&"Master", value)
	master_value.text = _format_percent(value)
	_save_settings()


func _on_music_volume_changed(value: float) -> void:
	_set_bus_volume(&"Music", value)
	music_value.text = _format_percent(value)
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	_set_bus_volume(&"SFX", value)
	sfx_value.text = _format_percent(value)
	_save_settings()


func _on_fullscreen_toggled(enabled: bool) -> void:
	if _updating_controls:
		return

	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	_save_settings()


func _set_bus_volume(bus_name: StringName, percent: float) -> void:
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


func _load_settings() -> void:
	var config := ConfigFile.new()
	var loaded := config.load(SETTINGS_PATH) == OK

	var master := float(config.get_value("audio", "master", _get_bus_percent(&"Master"))) if loaded else _get_bus_percent(&"Master")
	var music := float(config.get_value("audio", "music", _get_bus_percent(&"Music"))) if loaded else _get_bus_percent(&"Music")
	var sfx := float(config.get_value("audio", "sfx", _get_bus_percent(&"SFX"))) if loaded else _get_bus_percent(&"SFX")
	var fullscreen := bool(config.get_value("video", "fullscreen", _is_fullscreen())) if loaded else _is_fullscreen()

	_updating_controls = true
	master_slider.value = master
	music_slider.value = music
	sfx_slider.value = sfx
	fullscreen_toggle.button_pressed = fullscreen
	master_value.text = _format_percent(master)
	music_value.text = _format_percent(music)
	sfx_value.text = _format_percent(sfx)
	_updating_controls = false

	_set_bus_volume(&"Master", master)
	_set_bus_volume(&"Music", music)
	_set_bus_volume(&"SFX", sfx)
	if loaded:
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		DisplayServer.window_set_mode(mode)


func _save_settings() -> void:
	if _updating_controls:
		return

	var config := ConfigFile.new()
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.set_value("video", "fullscreen", fullscreen_toggle.button_pressed)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Não foi possível salvar as configurações: " + error_string(error))


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value)


func _apply_optional_art() -> void:
	panel_sprite_slot.texture = panel_texture
	title_icon_slot.texture = title_icon
	title_icon_slot.visible = title_icon != null
	continue_button.icon = continue_icon
	options_button.icon = options_icon
	quit_button.icon = quit_icon
	back_button.icon = back_icon
