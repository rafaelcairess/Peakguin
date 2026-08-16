extends Control

## Introducao do jogo. Cada quadro usa a mesma area 4:3 e pode conter
## uma ou mais legendas. Enter conclui/avanca a legenda e Esc pula a abertura.

const CUTSCENE_TEXTURES: Array[Texture2D] = [
	preload("res://ui/cutscenes/cena1.png"),
	preload("res://ui/cutscenes/cena2.jpg"),
	preload("res://ui/cutscenes/cena3.png"),
	preload("res://ui/cutscenes/cena4.png"),
	preload("res://ui/cutscenes/cena5.png"),
	preload("res://ui/cutscenes/cena6.png"),
	preload("res://ui/cutscenes/cena7.png"),
	preload("res://ui/cutscenes/cena8.png"),
]

const CUTSCENE_LINES: Array = [
	[
		"Pinguins são animais sociais.",
		"Em grupo, conservam calor, atravessam o inverno e aumentam suas chances de sobrevivência.",
	],
	[
		"Para um pinguim, sobreviver sempre significou permanecer junto aos outros.",
		"Juntos, enfrentam o frio.",
		"Juntos, encontram segurança.",
		"Juntos, sobrevivem.",
	],
	[
		"Foi assim para seus pais.",
		"E para aqueles que vieram antes deles.",
		"Durante gerações, o caminho sempre foi o mesmo.",
	],
	[
		"Alguns ficaram pelo caminho.",
		"E, como sempre, o tempo seguiu em frente.",
	],
	[
		"Mas algo já não era mais o mesmo.",
	],
	[
		"À frente, havia algo que ele não podia ignorar.",
	],
	[
		"E escolheu seguir sozinho.",
	],
	[
		"E talvez, pela primeira vez, outro pinguim também tenha começado a se perguntar, o que há além da montanha?",
	],
]

@export var next_scene: PackedScene
@export var cutscene_music: AudioStream
@export_range(0.01, 0.15, 0.005) var text_speed := 0.035
@export_range(0.1, 2.0, 0.05) var fade_duration := 0.55

@onready var scene_image: TextureRect = %SceneImage
@onready var subtitle: RichTextLabel = %Subtitle
@onready var continue_label: Label = %ContinueLabel
@onready var fade_overlay: ColorRect = %FadeOverlay
@onready var typewriter_timer: Timer = %TypewriterTimer

var _scene_index := 0
var _line_index := 0
var _is_typing := false
var _transitioning := true
var _continue_tween: Tween


func _ready() -> void:
	get_tree().paused = false
	RunTimer.pause_run()
	if PauseMenu.has_method("set_pause_allowed"):
		PauseMenu.set_pause_allowed(false)
	MusicManager.play_music(cutscene_music, 1.0)

	fade_overlay.color.a = 1.0
	_set_scene_content()
	await _fade_to(0.0)
	_transitioning = false


func _exit_tree() -> void:
	if PauseMenu.has_method("set_pause_allowed"):
		PauseMenu.set_pause_allowed(true)


func _input(event: InputEvent) -> void:
	if _transitioning:
		return
	if event is InputEventKey and event.echo:
		return

	if event.is_action_pressed("ui_cancel"):
		_finish_cutscene()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		_advance()
		get_viewport().set_input_as_handled()


func _set_scene_content() -> void:
	scene_image.texture = CUTSCENE_TEXTURES[_scene_index]
	_line_index = 0
	_show_line()


func _show_line() -> void:
	_set_continue_visible(false)
	subtitle.text = CUTSCENE_LINES[_scene_index][_line_index]
	subtitle.visible_characters = 0
	_is_typing = true
	typewriter_timer.wait_time = text_speed
	typewriter_timer.start()


func _advance() -> void:
	if _is_typing:
		subtitle.visible_characters = -1
		_is_typing = false
		typewriter_timer.stop()
		_set_continue_visible(true)
		return

	if _line_index + 1 < CUTSCENE_LINES[_scene_index].size():
		_line_index += 1
		_show_line()
	else:
		_go_to_next_scene()


func _go_to_next_scene() -> void:
	if _transitioning:
		return
	_transitioning = true
	_set_continue_visible(false)
	typewriter_timer.stop()

	await _fade_to(1.0)
	_scene_index += 1
	if _scene_index >= CUTSCENE_TEXTURES.size():
		_change_to_game()
		return

	_set_scene_content()
	await _fade_to(0.0)
	_transitioning = false


func _finish_cutscene() -> void:
	if _transitioning:
		return
	_transitioning = true
	_set_continue_visible(false)
	typewriter_timer.stop()
	await _fade_to(1.0)
	_change_to_game()


func _change_to_game() -> void:
	if next_scene == null:
		push_error("A cena seguinte da cutscene nao foi configurada.")
		_transitioning = false
		await _fade_to(0.0)
		return

	if PauseMenu.has_method("set_pause_allowed"):
		PauseMenu.set_pause_allowed(true)
	MusicManager.stop_music(0.6)
	var error := get_tree().change_scene_to_packed(next_scene)
	if error != OK:
		push_error("Nao foi possivel abrir a fase apos a cutscene: " + error_string(error))


func _fade_to(alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_overlay, "color:a", alpha, fade_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _set_continue_visible(value: bool) -> void:
	continue_label.visible = value
	if _continue_tween != null and _continue_tween.is_valid():
		_continue_tween.kill()
	_continue_tween = null
	continue_label.modulate.a = 1.0

	if value:
		_continue_tween = create_tween().set_loops()
		_continue_tween.tween_property(continue_label, "modulate:a", 0.35, 0.55).set_trans(Tween.TRANS_SINE)
		_continue_tween.tween_property(continue_label, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)


func _on_typewriter_timer_timeout() -> void:
	if subtitle.visible_characters < subtitle.get_total_character_count():
		subtitle.visible_characters += 1
	else:
		_is_typing = false
		typewriter_timer.stop()
		_set_continue_visible(true)
