extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	velocity = Vector2.ZERO
	anim.play("idle")
