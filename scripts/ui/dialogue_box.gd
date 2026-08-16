extends CanvasLayer

signal finished

@onready var text_label: RichTextLabel = %TextLabel
@onready var name_label: Label = %NameLabel
@onready var portrait_rect: TextureRect = %PortraitRect
@onready var background_panel: Panel = %BackgroundPanel
@onready var typewriter_timer: Timer = $TypewriterTimer
@onready var continue_label: Label = %ContinueLabel

var dialogue_lines: Array[String] = []
var current_line_index: int = 0
var is_typing: bool = false
var text_speed: float = 0.05

var _bounce_tween: Tween = null

func _ready() -> void:
	hide()

func start(lines: Array[String], speaker_name: String = "", portrait: Texture2D = null) -> void:
	dialogue_lines = lines
	current_line_index = 0

	if speaker_name == "":
		name_label.hide()
	else:
		name_label.text = speaker_name
		name_label.show()

	if portrait == null:
		portrait_rect.hide()
	else:
		portrait_rect.texture = portrait
		portrait_rect.show()

	show()
	show_line()

func show_line() -> void:
	_set_continue_visible(false)

	if current_line_index >= dialogue_lines.size():
		finished.emit()
		return

	text_label.text = dialogue_lines[current_line_index]
	text_label.visible_characters = 0
	is_typing = true

	typewriter_timer.wait_time = text_speed
	typewriter_timer.start()

func _advance() -> void:
	if is_typing:
		# Pula o typewriter — mostra tudo de uma vez
		text_label.visible_characters = -1
		is_typing = false
		typewriter_timer.stop()
		_set_continue_visible(true)
	else:
		current_line_index += 1
		show_line()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("interact"):
		_advance()
		get_viewport().set_input_as_handled()

func _set_continue_visible(value: bool) -> void:
	continue_label.visible = value

	if value:
		if _bounce_tween != null and _bounce_tween.is_valid():
			_bounce_tween.kill()
		_bounce_tween = create_tween().set_loops()
		_bounce_tween.tween_property(continue_label, "position:y", continue_label.position.y - 3.0, 0.4).set_ease(Tween.EASE_IN_OUT)
		_bounce_tween.tween_property(continue_label, "position:y", continue_label.position.y, 0.4).set_ease(Tween.EASE_IN_OUT)
	else:
		if _bounce_tween != null and _bounce_tween.is_valid():
			_bounce_tween.kill()
			_bounce_tween = null

func _on_typewriter_timer_timeout() -> void:
	if text_label.visible_characters < text_label.get_total_character_count():
		text_label.visible_characters += 1
	else:
		is_typing = false
		typewriter_timer.stop()
		_set_continue_visible(true)
