extends Node

## Mantem a resolucao logica pequena para o pixel art, mas abre uma janela
## confortavel em um multiplo inteiro. O limite de 1080p vale para modo janela;
## tela cheia acompanha o monitor sem alterar a area logica do jogo.

const BASE_SIZE := Vector2i(288, 208)
const MIN_SCALE := 2
const MAX_WINDOW_SIZE := Vector2i(1920, 1080)
const SCREEN_MARGIN := Vector2i(64, 64)
const DEFAULT_WINDOW_SIZE := Vector2i(1280, 720)
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

var selected_resolution := DEFAULT_WINDOW_SIZE


func _ready() -> void:
	if DisplayServer.get_name() == "headless":
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		_restore_windowed_size()


func set_fullscreen(enabled: bool) -> void:
	if DisplayServer.get_name() == "headless":
		return

	if enabled:
		# Remove o limite enquanto estiver em tela cheia; o viewport logico
		# continua em 288x208 e apenas a imagem final e ampliada.
		DisplayServer.window_set_max_size(Vector2i.ZERO)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_restore_windowed_size.call_deferred()


func set_resolution(resolution: Vector2i) -> void:
	if resolution not in RESOLUTIONS:
		resolution = DEFAULT_WINDOW_SIZE
	selected_resolution = resolution
	if DisplayServer.get_name() != "headless" \
			and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		_restore_windowed_size.call_deferred()


func get_resolution() -> Vector2i:
	return selected_resolution


func _restore_windowed_size() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var available := usable_rect.size - SCREEN_MARGIN
	var target_size := selected_resolution
	if target_size.x > available.x or target_size.y > available.y:
		var fit_ratio := minf(
			float(available.x) / float(target_size.x),
			float(available.y) / float(target_size.y)
		)
		target_size = Vector2i(Vector2(target_size) * fit_ratio)

	DisplayServer.window_set_min_size(BASE_SIZE * MIN_SCALE)
	DisplayServer.window_set_max_size(MAX_WINDOW_SIZE)
	DisplayServer.window_set_size(target_size)
	DisplayServer.window_set_position(
		usable_rect.position + (usable_rect.size - target_size) / 2
	)
