extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector
@onready var left_ground_detector: RayCast2D = $LeftGroundDetector
@onready var right_ground_detector: RayCast2D = $RightGroundDetector

@export var speed: float = 20.0
@export_range(-1.0, 1.0, 2.0) var initial_direction: float = 1.0

var direction: float = 1.0


func _ready() -> void:
	direction = initial_direction
	update_direction()


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	apply_gravity(delta)

	if should_turn_around():
		turn_around()

	velocity.x = direction * speed
	move_and_slide()


func should_turn_around() -> bool:
	if is_on_wall():
		return true

	if direction < 0:
		return left_wall_detector.is_colliding() or (
			is_on_floor() and not left_ground_detector.is_colliding()
		)

	return right_wall_detector.is_colliding() or (
		is_on_floor() and not right_ground_detector.is_colliding()
	)


func turn_around() -> void:
	direction *= -1.0
	update_direction()


func update_direction() -> void:
	sprite.flip_h = direction < 0


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
