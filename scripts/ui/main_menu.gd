extends Control

## Menu principal do Peakguin
##
## O fundo cicla automaticamente entre os backgrounds dos 4 biomas
## (Pradaria → Floresta → Trópicos → Inverno) usando crossfade suave.
## Fases e visual podem ser trocados pelo Inspector.

const PLAYER_SCENE := "res://entities/player/player.tscn"

## Quanto tempo cada bioma fica visível antes de trocar (em segundos).
const BG_DISPLAY_TIME := 8.0
## Duração do crossfade entre um bioma e o próximo (em segundos).
const BG_FADE_TIME := 2.0

# ─── Exports configuráveis pelo Inspector ───

@export_category("Fases")
@export var default_level: PackedScene
@export var intro_scene: PackedScene
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
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var master_value: Label = %MasterValue
@onready var music_value: Label = %MusicValue
@onready var sfx_value: Label = %SFXValue
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var apply_video_button: Button = %ApplyVideoButton
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
	_setup_resolution_options()
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
	apply_video_button.pressed.connect(_on_apply_video_pressed)


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
	version_label.text = "v" + String(ProjectSettings.get_setting(
		"application/config/version",
		"0.02 Pre-Alpha"
	))

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
			var normal_style := _make_texture_style(button_texture)
			button.add_theme_stylebox_override("normal", normal_style)
			button.add_theme_stylebox_override("disabled", normal_style)
		if button_hover_texture != null:
			var hover_style := _make_texture_style(button_hover_texture)
			button.add_theme_stylebox_override("hover", hover_style)
			button.add_theme_stylebox_override("focus", hover_style)
			button.add_theme_stylebox_override("pressed", hover_style)


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
		apply_video_button,
		settings_back_button,
		credits_back_button,
	]


func _make_texture_style(texture: Texture2D) -> StyleBoxTexture:
	## Cria um StyleBoxTexture a partir de uma imagem, com margem de 4px.
	## Usado quando o usuário fornece texturas customizadas para os botões.
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.content_margin_left = 7.0
	style.content_margin_top = 3.0
	style.content_margin_right = 7.0
	style.content_margin_bottom = 3.0
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
	_load_settings()
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
	if intro_scene != null:
		_start_level(intro_scene)
	else:
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


func _on_apply_video_pressed() -> void:
	var index := resolution_option.selected
	if index < 0 or index >= WindowManager.RESOLUTIONS.size():
		return
	SettingsManager.set_video(
		WindowManager.RESOLUTIONS[index],
		fullscreen_toggle.button_pressed
	)
	_save_settings()


func _setup_resolution_options() -> void:
	resolution_option.clear()
	for resolution in WindowManager.RESOLUTIONS:
		var label := "%d x %d" % [resolution.x, resolution.y]
		resolution_option.add_item(label)


func _resolution_index(resolution: Vector2i) -> int:
	var index := WindowManager.RESOLUTIONS.find(resolution)
	return index if index >= 0 else WindowManager.RESOLUTIONS.find(WindowManager.DEFAULT_WINDOW_SIZE)


func _load_settings() -> void:
	# _updating_controls evita que os callbacks de value_changed salvem
	# as configurações enquanto estamos apenas carregando valores.
	_updating_controls = true
	master_slider.value = SettingsManager.master_volume
	music_slider.value = SettingsManager.music_volume
	sfx_slider.value = SettingsManager.sfx_volume
	fullscreen_toggle.button_pressed = SettingsManager.fullscreen
	resolution_option.select(_resolution_index(SettingsManager.resolution))
	master_value.text = _format_percent(SettingsManager.master_volume)
	music_value.text = _format_percent(SettingsManager.music_volume)
	sfx_value.text = _format_percent(SettingsManager.sfx_volume)
	_updating_controls = false


func _save_settings() -> void:
	if _updating_controls:
		return
	SettingsManager.save_settings()


func _format_percent(value: float) -> String:
	return "%d%%" % roundi(value)
