extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var interactable_area: Area2D = $InteractableArea

var has_given_power: bool = false

var dialogue_lines: Array[String] = [
	"Ah, um pinguim por aqui...",
	"Você está longe de casa, pequeno.",
	"Sinto que há algo especial em você.",
	"Deixe-me lhe dar um presente das profundezas...",
	"Agora você pode pular duas vezes no ar!",
	"Use bem esse dom, viajante."
]

func _ready() -> void:
	velocity = Vector2.ZERO
	anim.play("idle")
	if interactable_area:
		interactable_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	var portrait = anim.sprite_frames.get_frame_texture("idle", 0)
	DialogueManager.start_dialogue(dialogue_lines, "Sereia", portrait)

	if not has_given_power:
		# Conecta uma única vez ao sinal de fim de diálogo para dar o poder
		DialogueManager.dialogue_ended.connect(_on_power_granted, CONNECT_ONE_SHOT)

func _on_power_granted() -> void:
	if has_given_power:
		return
	has_given_power = true

	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		players[0].unlock_double_jump()
