extends Control

## Menu principal do Peakguin — estilo Fields of Mistria.
##
## O fundo cicla automaticamente entre os backgrounds dos 4 biomas
## (Pradaria → Floresta → Trópicos → Inverno) usando crossfade suave.
## Fases e visual podem ser trocados pelo Inspector.

const PLAYER_SCENE := "res://entities/player/player.tscn"
const SETTINGS_PATH := "user://settings.cfg"
const MIN_VOLUME_DB := -80.0

## Quanto tempo cada bioma fica visível antes de trocar (em segundos).
const BG_DISPLAY_TIME := 8.0
## Duração do crossfade entre um bioma e o próximo (em segundos).
const BG_FADE_TIME := 2.0

# ─── Exports configuráveis pelo Inspector ───

@export_category("Fases")
@export var default_level: PackedScene
@export var grassland_level: PackedScene
@export var winter_level: PackedScene
@export var forest_level: PackedScene
@export var tropic_level: PackedScene

@export_category("Visual")
@export var title_text := "PEAKGUIN"
@export var background_color := Color("101b2b")
@export var background_texture: Texture2D
@export var logo_texture: Texture2D
@export var button_texture: Texture2D
@export var button_hover_texture: Texture2D

## Lista de texturas de fundo que serão cicladas com crossfade.
## Configure pelo Inspector arrastando as imagens _Complete_static_BG_ de cada bioma.
@export var bg_textures: Array[Texture2D] = []

@export_category("Icones opcionais")
@export var play_icon: Texture2D
@export var new_game_icon: Texture2D
@export var levels_icon: Texture2D
@export var settings_icon: Texture2D
@export var credits_icon: Texture2D
@export var quit_icon: Texture2D
@export var back_icon: Texture2D

@export_category("Musica")
@export var menu_music: AudioStream

# ─── Referências aos nós da cena ───
# O "%NomeDoNo" busca o nó pelo unique_name definido na cena.

@export var bg_scroll_speed := 8.0

@onready var bg_scroller: Node2D = %BgScroller
@onready var bg_tile_0: Sprite2D = %BgTile0
@onready var bg_tile_1: Sprite2D = %BgTile1
@onready var bg_tile_2: Sprite2D = %BgTile2
@onready var bg_fade: ColorRect = %BgFade
@onready var background_slot: TextureRect = %BackgroundSlot
@onready var logo_slot: TextureRect = %LogoSlot
@onready var title_label: Label = %TitleLabel
@onready var main_screen: Control = %MainScreen
@onready var levels_screen: Control = %LevelsScreen
@onready var settings_screen: Control = %SettingsScreen
@onready var credits_screen: Control = %CreditsScreen
@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var levels_button: Button = %LevelsButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton
@onready var grassland_button: Button = %GrasslandButton
@onready var winter_button: Button = %WinterButton
@onready var forest_button: Button = %ForestButton
@onready var tropic_button: Button = %TropicButton
@onready var levels_back_button: Button = %LevelsBackButton
@onready var settings_back_button: Button = %SettingsBackButton
@onready var credits_back_button: Button = %CreditsBackButton
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var menu_music_player: AudioStreamPlayer = %MenuMusic
@onready var penguin_preview: AnimatedSprite2D = %PenguinPreview
@onready var penguin_sitting: AnimatedSprite2D = %PenguinSitting
@onready var version_label: Label = %VersionLabel
@onready var copyright_label: Label = %CopyrightLabel
@onready var transition: ColorRect = %Transition

var _updating_controls := false
var _starting_game := false

## Índice da textura de fundo que está sendo exibida ATUALMENTE na frente.
var _bg_current_index := 0

## Timer interno para controlar quando trocar o fundo.
## Não usamos um nó Timer — em vez disso usamos um loop com await.
var _bg_cycling := false


# ═══════════════════════════════════════════════════════════
#  INICIALIZAÇÃO
# ═══════════════════════════════════════════════════════════

func _ready() -> void:
	get_tree().paused = false
	if PauseMenu.has_method("set_pause_allowed"):
		PauseMenu.set_pause_allowed(false)

	RunTimer.pause_run()

	_connect_interface()
	_apply_optional_art()
	_setup_penguin()
	_setup_continue_button()
	_load_settings()
	_show_main_screen()

	# Inicia a música do menu (se configurada).
	var selected_music := menu_music
	if selected_music == null:
		selected_music = menu_music_player.stream
	if selected_music != null:
		MusicManager.play_music(selected_music, 0.8)

	# Inicia o ciclo de crossfade dos backgrounds.
	_start_bg_cycle()


func _exit_tree() -> void:
	# Para o ciclo de crossfade quando o menu é destruído (ex: ao entrar numa fase).
	_bg_cycling = false
	if PauseMenu.has_method("set_pause_allowed"):
		PauseMenu.set_pause_allowed(true)

func _process(delta: float) -> void:
	if bg_scroller != null:
		bg_scroller.position.x -= bg_scroll_speed * delta
		if bg_scroller.position.x <= -288.0:
			bg_scroller.position.x += 288.0


# ═══════════════════════════════════════════════════════════
#  CROSSFADE DE BACKGROUNDS
# ═══════════════════════════════════════════════════════════
#
# Como funciona:
#
#   Temos DUAS TextureRect sobrepostas: bg_back (atrás) e bg_front (na frente).
#   Ambas cobrem a tela inteira.
#
#   1. bg_front mostra o bioma atual (alpha = 1, totalmente visível).
#   2. Quando chega a hora de trocar, colocamos o PRÓXIMO bioma no bg_back.
#   3. Usamos um Tween para diminuir o alpha de bg_front de 1 → 0 (fade out).
#      Isso revela o bg_back por baixo — que é o próximo bioma.
#   4. Quando o fade termina, trocamos: bg_front recebe a textura do bg_back
#      e volta para alpha = 1. Pronto para o próximo ciclo.
#
#   Resultado visual: transição suave entre Pradaria → Floresta → Trópicos → Inverno → ...

func _start_bg_cycle() -> void:
	if bg_textures.size() < 2:
		return

	_bg_cycling = true
	_bg_current_index = 0

	# Garante que a primeira textura está visível.
	bg_tile_0.texture = bg_textures[0]
	bg_tile_1.texture = bg_textures[0]
	bg_tile_2.texture = bg_textures[0]
	bg_fade.color.a = 0.0

	_bg_cycle_loop()


func _bg_cycle_loop() -> void:
	while _bg_cycling:
		await get_tree().create_timer(BG_DISPLAY_TIME).timeout

		if not _bg_cycling or not is_inside_tree():
			return

		var next_index := (_bg_current_index + 1) % bg_textures.size()

		# Fade para preto/cor usando o BgFade
		var fade_in := create_tween()
		fade_in.tween_property(bg_fade, "color:a", 1.0, BG_FADE_TIME / 2.0)
		await fade_in.finished

		if not _bg_cycling or not is_inside_tree():
			return

		# Troca as texturas enquanto está coberto pelo fade
		bg_tile_0.texture = bg_textures[next_index]
		bg_tile_1.texture = bg_textures[next_index]
		bg_tile_2.texture = bg_textures[next_index]
		_bg_current_index = next_index

		# Fade voltando
		var fade_out := create_tween()
		fade_out.tween_property(bg_fade, "color:a", 0.0, BG_FADE_TIME / 2.0)
		await fade_out.finished


# ═══════════════════════════════════════════════════════════
#  CONEXÕES DE INTERFACE
# ═══════════════════════════════════════════════════════════

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return

	# ESC volta para a tela principal quando estiver numa sub-tela.
	if event.is_action_pressed("ui_cancel") and not main_screen.visible:
		_show_main_screen()
		get_viewport().set_input_as_handled()


func _connect_interface() -> void:
	# Conecta cada botão à sua função correspondente.
	# .bind(argumento) passa dados extras para a função — ex: qual fase carregar.
	continue_button.pressed.connect(_continue_game)
	new_game_button.pressed.connect(_start_new_game)
	levels_button.pressed.connect(_show_levels_screen)
	settings_button.pressed.connect(_show_settings_screen)
	credits_button.pressed.connect(_show_credits_screen)
	quit_button.pressed.connect(_on_quit_pressed)

	grassland_button.pressed.connect(_start_level.bind(grassland_level))
	winter_button.pressed.connect(_start_level.bind(winter_level))
	forest_button.pressed.connect(_start_level.bind(forest_level))
	tropic_button.pressed.connect(_start_level.bind(tropic_level))
	levels_back_button.pressed.connect(_show_main_screen)
	settings_back_button.pressed.connect(_show_main_screen)
	credits_back_button.pressed.connect(_show_main_screen)

	# Sliders e fullscreen — cada vez que o valor muda, atualiza o áudio.
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)


# ═══════════════════════════════════════════════════════════
#  BOTÃO "JOGAR" (CONTINUAR SAVE)
# ═══════════════════════════════════════════════════════════

func _setup_continue_button() -> void:
	## O botão "Jogar" só aparece se o jogador tem um checkpoint ativo
	## (ex: voltou ao menu sem fechar o jogo). O CheckpointManager armazena
	## isso em memória — não persiste entre sessões.
	var has_save := CheckpointManager.has_active_checkpoint
	continue_button.visible = has_save


# ═══════════════════════════════════════════════════════════
#  ARTE E VISUAL
# ═══════════════════════════════════════════════════════════

func _apply_optional_art() -> void:
	# Se uma textura customizada foi fornecida via Inspector, sobrepõe o fundo.
	if background_texture != null:
		background_slot.texture = background_texture
		background_slot.visible = true
	else:
		background_slot.visible = false

	# Logo vs texto: se tem logo, esconde o texto e vice-versa.
	logo_slot.texture = logo_texture
	logo_slot.visible = logo_texture != null
	title_label.text = title_text
	title_label.visible = logo_texture == null

	# Ícones opcionais nos botões.
	continue_button.icon = play_icon
	new_game_button.icon = new_game_icon
	levels_button.icon = levels_icon
	settings_button.icon = settings_icon
	credits_button.icon = credits_icon
	quit_button.icon = quit_icon
	levels_back_button.icon = back_icon
	settings_back_button.icon = back_icon
	credits_back_button.icon = back_icon

	# Se texturas de botão foram fornecidas, aplica em TODOS os botões.
	for button in _get_all_buttons():
		if button_texture != null:
			button.add_theme_stylebox_override("normal", _make_texture_style(button_texture))
		if button_hover_texture != null:
			var hover_style := _make_texture_style(button_hover_texture)
			button.add_theme_stylebox_override("hover", hover_style)
			button.add_theme_stylebox_override("focus", hover_style)


func _setup_penguin() -> void:
	## Respeita a animação e os frames configurados diretamente no AnimatedSprite2D pelo editor.
	## Se não houver frames, tenta carregar direto da cena do jogador.
	
	# === PREVIEW ===
	if penguin_preview.sprite_frames == null:
		var packed_player := load(PLAYER_SCENE) as PackedScene
		if packed_player != null:
			var player_instance := packed_player.instantiate()
			var player_sprite := player_instance.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
			if player_sprite != null:
				penguin_preview.sprite_frames = player_sprite.sprite_frames
			player_instance.free()
			
	if penguin_preview.sprite_frames != null:
		penguin_preview.show()
		var anim = penguin_preview.animation
		if anim != &"":
			penguin_preview.play(anim)
		else:
			penguin_preview.play()
	else:
		penguin_preview.hide()
		
	# === SITTING ===
	if penguin_sitting.sprite_frames == null:
		penguin_sitting.sprite_frames = penguin_preview.sprite_frames
		
	if penguin_sitting.sprite_frames != null:
		penguin_sitting.show()
		var anim = penguin_sitting.animation
		if anim != &"":
			penguin_sitting.play(anim)
		else:
			penguin_sitting.play()
	else:
		penguin_sitting.hide()


func _get_all_buttons() -> Array[Button]:
	return [
		continue_button,
		new_game_button,
		levels_button,
		settings_button,
		credits_button,
		quit_button,
		grassland_button,
		winter_button,
		forest_button,
		tropic_button,
		levels_back_button,
		settings_back_button,
		credits_back_button,
	]


func _make_texture_style(texture: Texture2D) -> StyleBoxTexture:
	## Cria um StyleBoxTexture a partir de uma imagem, com margem de 4px.
	## Usado quando o usuário fornece texturas customizadas para os botões.
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.texture_margin_left = 4.0
	style.texture_margin_top = 4.0
	style.texture_margin_right = 4.0
	style.texture_margin_bottom = 4.0
	return style


# ═══════════════════════════════════════════════════════════
#  NAVEGAÇÃO ENTRE TELAS
# ═══════════════════════════════════════════════════════════

func _hide_all_screens() -> void:
	main_screen.hide()
	levels_screen.hide()
	settings_screen.hide()
	credits_screen.hide()


func _show_main_screen() -> void:
	_hide_all_screens()
	main_screen.show()
	# Foca no botão certo — "Jogar" se disponível, senão "Novo Jogo".
	if continue_button.visible:
		continue_button.grab_focus()
	else:
		new_game_button.grab_focus()


func _show_levels_screen() -> void:
	_hide_all_screens()
	levels_screen.show()
	grassland_button.grab_focus()


func _show_settings_screen() -> void:
	_hide_all_screens()
	settings_screen.show()
	master_slider.grab_focus()


func _show_credits_screen() -> void:
	_hide_all_screens()
	credits_screen.show()
	credits_back_button.grab_focus()


# ═══════════════════════════════════════════════════════════
#  INICIAR JOGO
# ═══════════════════════════════════════════════════════════

func _continue_game() -> void:
	## Continua a partir do checkpoint ativo (mesma sessão).
	if not CheckpointManager.has_active_checkpoint:
		_start_level(default_level)
		return

	var scene_path := CheckpointManager.active_scene_path
	if scene_path.is_empty():
		_start_level(default_level)
		return

	var level := load(scene_path) as PackedScene
	if level == null:
		push_warning("Não foi possível carregar a fase do checkpoint: " + scene_path)
		_start_level(default_level)
		return

	_start_level(level)


func _start_new_game() -> void:
	## Limpa qualquer checkpoint/save e inicia a fase padrão do zero.
	CheckpointManager.clear_checkpoint()
	RunTimer.reset_run()
	_start_level(default_level)


func _start_level(level: PackedScene) -> void:
	## Faz o fade-to-black e carrega a fase. _starting_game evita cliques duplos.
	if _starting_game:
		return
	if level == null:
		push_warning("Nenhuma fase foi configurada para este botao.")
		return

	_starting_game = true
	_bg_cycling = false  # Para o crossfade — não precisamos mais dele.

	# Bloqueia cliques na tela durante o fade.
	transition.mouse_filter = Control.MOUSE_FILTER_STOP

	# Cria um Tween que anima o alpha do ColorRect de 0 → 1 (transparente → preto).
	var fade := create_tween()
	fade.tween_property(transition, "color:a", 1.0, 0.25)
	await fade.finished

	if PauseMenu.has_method("set_pause_allowed"):
		PauseMenu.set_pause_allowed(true)

	var error := get_tree().change_scene_to_packed(level)
	if error != OK:
		push_error("Nao foi possivel abrir a fase: " + error_string(error))
		_starting_game = false
		transition.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition.color.a = 0.0


func _on_quit_pressed() -> void:
	get_tree().quit()


# ═══════════════════════════════════════════════════════════
#  ÁUDIO E CONFIGURAÇÕES
# ═══════════════════════════════════════════════════════════

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


func _load_settings() -> void:
	var config := ConfigFile.new()
	var loaded := config.load(SETTINGS_PATH) == OK
	var master := float(config.get_value("audio", "master", _get_bus_percent(&"Master"))) if loaded else _get_bus_percent(&"Master")
	var music := float(config.get_value("audio", "music", _get_bus_percent(&"Music"))) if loaded else _get_bus_percent(&"Music")
	var sfx := float(config.get_value("audio", "sfx", _get_bus_percent(&"SFX"))) if loaded else _get_bus_percent(&"SFX")
	var fullscreen := bool(config.get_value("video", "fullscreen", _is_fullscreen())) if loaded else _is_fullscreen()

	# _updating_controls evita que os callbacks de value_changed salvem
	# as configurações enquanto estamos apenas carregando valores.
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
	config.load(SETTINGS_PATH)
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.set_value("video", "fullscreen", fullscreen_toggle.button_pressed)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Nao foi possivel salvar as configuracoes: " + error_string(error))


func _set_bus_volume(bus_name: StringName, percent: float) -> void:
	## Converte o percentual (0-100) para decibéis e aplica no bus de áudio.
	## 0% = mudo (-80 dB), 100% = volume máximo (0 dB).
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Bus de audio nao encontrado: " + String(bus_name))
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


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value)
