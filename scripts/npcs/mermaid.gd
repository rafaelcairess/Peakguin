extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


@onready var interactable_area: Area2D = $InteractableArea

var dialogue_lines: Array[String] = [
	"Olá, viajante!",
	"Cuidado com a água fria.",
	"Tem muitos perigos por aqui."
]

func _ready() -> void:
	velocity = Vector2.ZERO
	anim.play("idle")
	if interactable_area:
		interactable_area.interacted.connect(_on_interacted)

func _on_interacted() -> void:
	var portrait = anim.sprite_frames.get_frame_texture("idle", 0)
	DialogueManager.start_dialogue(dialogue_lines, "Sereia", portrait)
