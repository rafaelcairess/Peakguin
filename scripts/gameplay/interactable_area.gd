class_name InteractableArea
extends Area2D

signal interacted

@export var interact_prompt: String = "Interagir"

func interact() -> void:
	interacted.emit()
