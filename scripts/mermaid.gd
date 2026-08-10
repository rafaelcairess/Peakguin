extends CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var left_detector: RayCast2D = $LeftDetector
@onready var right_detector: RayCast2D = $RightDetector

@export var speed: float = 25.0

var direction: float = 1.0


func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	go_to_swim_state()


func _physics_process(_delta: float) -> void:
	swim_state()
	move_and_slide()


func go_to_swim_state() -> void:
	anim.play("idle")
	update_direction()


func swim_state() -> void:
	if should_turn_around():
		direction *= -1.0
		update_direction()

	velocity = Vector2(direction * speed, 0)


func should_turn_around() -> bool:
	if direction < 0:
		return left_detector.is_colliding()

	return right_detector.is_colliding()


func update_direction() -> void:
	anim.flip_h = direction < 0
