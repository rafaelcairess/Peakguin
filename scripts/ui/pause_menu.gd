extends CanvasLayer

## Menu de pausa global.
## A cena fica registrada como Autoload e, por isso, funciona em todas as fases.

@export_category("Arte opcional")
@export var panel_texture: Texture2D
@export var title_icon: Texture2D
@export var button_texture: Texture2D
@export var button_hover_texture: Texture2D
@export var continue_icon: Texture2D
@export var options_icon: Texture2D
@export var quit_icon: Texture2D
@export var back_icon: Texture2D

@onready var overlay: Control = $Overlay
@onready var panel_sprite_slot: TextureRect = %PanelSpriteSlot
@onready var title_icon_slot: TextureRect = %TitleIconSlot
@onready var main_screen: VBoxContainer = %MainScreen
@onready var options_screen: VBoxContainer = %OptionsScreen
@onready var audio_debug_screen: VBoxContainer = %AudioDebugScreen
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var back_button: Button = %BackButton
@onready var audio_debug_button: Button = %AudioDebugButton
@onready var audio_debug_back_button: Button = %AudioDebugBackButton
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var jump_slider: HSlider = %JumpSlider
@onready var steps_slider: HSlider = %StepsSlider
@onready var footstep_cutoff_slider: HSlider = %FootstepCutoffSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue
@onready var jump_value: Label = %JumpValue
@onready var steps_value: Label = %StepsValue
@onready var footstep_cutoff_value: Label = %FootstepCutoffValue
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var jump_preview: AudioStreamPlayer = %JumpPreview
@onready var steps_preview: AudioStreamPlayer = %StepsPreview

var _updating_controls := false
var pause_allowed := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_optional_art()
	overlay.hide()
	_load_settings()
	_show_main_screen()


func _process(_delta: float) -> void:
	if steps_preview.playing \
			and steps_preview.get_playback_position() >= SettingsManager.footstep_cutoff_seconds:
		steps_preview.stop()


func _input(event: InputEvent) -> void:
	if not pause_allowed:
		return

	if event is InputEventKey and event.echo:
		return

	if not event.is_action_pressed("ui_cancel"):
		return

	if not overlay.visible:
		open_menu()
	elif audio_debug_screen.visible:
		_show_options_screen()
	elif options_screen.visible:
		_show_main_screen()
	else:
		close_menu()

	get_viewport().set_input_as_handled()


func set_pause_allowed(allowed: bool) -> void:
	pause_allowed = allowed
	if not pause_allowed:
		overlay.hide()
		get_tree().paused = false
		RunTimer.resume_run()


func open_menu() -> void:
	get_tree().paused = true
	RunTimer.pause_run()
	overlay.show()
	_show_main_screen()
	continue_button.grab_focus()


func close_menu() -> void:
	overlay.hide()
	get_tree().paused = false
	RunTimer.resume_run()


func _show_main_screen() -> void:
	main_screen.show()
	options_screen.hide()
	audio_debug_screen.hide()
	if overlay.visible:
		continue_button.grab_focus()


func _show_options_screen() -> void:
	_load_settings()
	main_screen.hide()
	options_screen.show()
	audio_debug_screen.hide()
	master_slider.grab_focus()


func _show_audio_debug_screen() -> void:
	main_screen.hide()
	options_screen.hide()
	audio_debug_screen.show()
	jump_slider.grab_focus()


func _on_continue_pressed() -> void:
	close_menu()


func _on_options_pressed() -> void:
	_show_options_screen()


func _on_back_pressed() -> void:
	_show_main_screen()


func _on_audio_debug_pressed() -> void:
	_show_audio_debug_screen()


func _on_audio_debug_back_pressed() -> void:
	_show_options_screen()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	RunTimer.resume_run()
	get_tree().change_scene_to_file("res://ui/main_menu/main_menu.tscn")


func _on_master_volume_changed(value: float) -> void:
	if _updating_controls:
		return
	SettingsManager.set_master_volume(value)
	master_value.text = _format_percent(value)
	_save_settings()


func _on_music_volume_changed(value: float) -> void:
	if _updating_controls:
		return
	SettingsManager.set_music_volume(value)
	music_value.text = _format_percent(value)
	_save_settings()


func _on_sfx_volume_changed(value: float) -> void:
	if _updating_controls:
		return
	SettingsManager.set_sfx_volume(value)
	sfx_value.text = _format_percent(value)
	_save_settings()


func _on_jump_volume_changed(value: float) -> void:
	if _updating_controls:
		return
	SettingsManager.set_jump_volume(value)
	jump_value.text = _format_percent(value)
	_save_settings()


func _on_steps_volume_changed(value: float) -> void:
	if _updating_controls:
		return
	SettingsManager.set_steps_volume(value)
	steps_value.text = _format_percent(value)
	_save_settings()


func _on_footstep_cutoff_changed(value: float) -> void:
	if _updating_controls:
		return
	SettingsManager.set_footstep_cutoff(value)
	footstep_cutoff_value.text = _format_seconds(value)
	_save_settings()


func _on_jump_preview_pressed() -> void:
	jump_preview.stop()
	jump_preview.play()


func _on_steps_preview_pressed() -> void:
	steps_preview.stop()
	steps_preview.play()


func _on_fullscreen_toggled(enabled: bool) -> void:
	if _updating_controls:
		return

	SettingsManager.set_fullscreen(enabled)
	_save_settings()


func _load_settings() -> void:
	_updating_controls = true
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	jump_slider.value = SettingsManager.jump_volume
	steps_slider.value = SettingsManager.steps_volume
	footstep_cutoff_slider.value = SettingsManager.footstep_cutoff_seconds
	fullscreen_toggle.button_pressed = SettingsManager.fullscreen
	master_value.text = _format_percent(SettingsManager.master_volume)
	music_value.text = _format_percent(SettingsManager.music_volume)
	sfx_value.text = _format_percent(SettingsManager.sfx_volume)
	jump_value.text = _format_percent(SettingsManager.jump_volume)
	steps_value.text = _format_percent(SettingsManager.steps_volume)
	footstep_cutoff_value.text = _format_seconds(SettingsManager.footstep_cutoff_seconds)
	_updating_controls = false


func _save_settings() -> void:
	if _updating_controls:
		return
	SettingsManager.save_settings()


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value)


func _format_seconds(value: float) -> String:
	return "%.2fs" % value


func _apply_optional_art() -> void:
	panel_sprite_slot.texture = panel_texture
	title_icon_slot.texture = title_icon
	title_icon_slot.visible = title_icon != null
	for node in overlay.find_children("*", "Button", true, false):
		var button := node as Button
		if button_texture != null:
			var normal_style := _make_texture_style(button_texture)
			button.add_theme_stylebox_override("normal", normal_style)
			button.add_theme_stylebox_override("disabled", normal_style)
		if button_hover_texture != null:
			var hover_style := _make_texture_style(button_hover_texture)
			button.add_theme_stylebox_override("hover", hover_style)
			button.add_theme_stylebox_override("focus", hover_style)
			button.add_theme_stylebox_override("pressed", hover_style)
	continue_button.icon = continue_icon
	options_button.icon = options_icon
	quit_button.icon = quit_icon
	back_button.icon = back_icon
	audio_debug_back_button.icon = back_icon


func _make_texture_style(texture: Texture2D) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = 7.0
	style.content_margin_top = 3.0
	style.content_margin_right = 7.0
	style.content_margin_bottom = 3.0
	return style
