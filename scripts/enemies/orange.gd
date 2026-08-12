extends CharacterBody2D

enum OrangeState {
	walk,
	roll_start,
	rolling,
	roll_stop,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var roll_damage_shape: CollisionShape2D = $RollDamage/CollisionShape2D
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var roll_duration_timer: Timer = $RollDurationTimer
@onready var roll_cooldown_timer: Timer = $RollCooldownTimer
@onready var death_timer: Timer = $DeathTimer

@export var speed: float = 20.0
@export var roll_speed: float = 90.0
@export_range(-1, 1, 2) var initial_direction: int = 1
@export_range(0.1, 10.0, 0.1) var roll_duration_seconds: float = 1.2
@export_range(0.1, 10.0, 0.1) var roll_cooldown_seconds: float = 2.0

const WALL_DETECTOR_OFFSET_X: float = 8.0
const WALL_DETECTOR_LENGTH: float = 14.0
const GROUND_DETECTOR_OFFSET_X: float = 11.0
const PLAYER_DETECTOR_OFFSET_X: float = 8.0
const PLAYER_DETECTOR_LENGTH: float = 88.0

var status: OrangeState = OrangeState.walk
var direction: int = 1
var can_roll: bool = true


func _ready() -> void:
	direction = initial_direction
	roll_duration_timer.wait_time = roll_duration_seconds
	roll_cooldown_timer.wait_time = roll_cooldown_seconds
	hitbox_shape.disabled = false
	roll_damage_shape.disabled = true
	update_direction()
	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	player_detector.force_raycast_update()
	go_to_walk_state()


func _physics_process(delta: float) -> void:
	if status != OrangeState.dead and not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		OrangeState.walk:
			walk_state()

		OrangeState.roll_start:
			roll_start_state()

		OrangeState.rolling:
			rolling_state()

		OrangeState.roll_stop:
			roll_stop_state()

		OrangeState.dead:
			dead_state()

	move_and_slide()


func go_to_walk_state() -> void:
	status = OrangeState.walk
	anim.play("walking")


func go_to_roll_start_state() -> void:
	if not can_roll or status == OrangeState.dead:
		return

	status = OrangeState.roll_start
	velocity.x = 0.0
	can_roll = false
	anim.play("roll_start")


func go_to_rolling_state() -> void:
	if status == OrangeState.dead:
		return

	status = OrangeState.rolling
	anim.play("rolling")
	set_roll_damage_active(true)
	roll_duration_timer.start()


func go_to_roll_stop_state() -> void:
	if status in [OrangeState.roll_stop, OrangeState.dead]:
		return

	status = OrangeState.roll_stop
	velocity.x = 0.0
	roll_duration_timer.stop()
	set_roll_damage_active(false)
	anim.play("roll_stop")


func go_to_dead_state() -> void:
	if status in [OrangeState.rolling, OrangeState.dead]:
		return

	status = OrangeState.dead
	velocity = Vector2.ZERO
	roll_duration_timer.stop()
	roll_cooldown_timer.stop()
	hitbox_shape.set_deferred("disabled", true)
	roll_damage_shape.set_deferred("disabled", true)
	collision_shape.set_deferred("disabled", true)
	anim.play("afk")
	death_timer.start()


func walk_state() -> void:
	velocity.x = speed * direction

	if is_on_floor() and (
		wall_detector.is_colliding()
		or not ground_detector.is_colliding()
	):
		turn_around()
		return

	if can_roll and player_detector.is_colliding():
		go_to_roll_start_state()


func roll_start_state() -> void:
	velocity.x = 0.0


func rolling_state() -> void:
	velocity.x = roll_speed * direction

	if is_on_floor() and (
		wall_detector.is_colliding()
		or not ground_detector.is_colliding()
	):
		go_to_roll_stop_state()


func roll_stop_state() -> void:
	velocity.x = 0.0


func dead_state() -> void:
	velocity = Vector2.ZERO


func turn_around() -> void:
	direction *= -1
	velocity.x = 0.0
	update_direction()
	update_detectors_immediately()


func update_direction() -> void:
	anim.flip_h = direction < 0
	wall_detector.position.x = WALL_DETECTOR_OFFSET_X * direction
	wall_detector.target_position.x = WALL_DETECTOR_LENGTH * direction
	ground_detector.position.x = GROUND_DETECTOR_OFFSET_X * direction
	player_detector.position.x = PLAYER_DETECTOR_OFFSET_X * direction
	player_detector.target_position.x = PLAYER_DETECTOR_LENGTH * direction


func update_detectors_immediately() -> void:
	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	player_detector.force_raycast_update()


func set_roll_damage_active(active: bool) -> void:
	hitbox_shape.set_deferred("disabled", active)
	roll_damage_shape.set_deferred("disabled", not active)


func take_damage() -> void:
	go_to_dead_state()


func _on_animated_sprite_2d_animation_finished() -> void:
	if status == OrangeState.roll_start:
		go_to_rolling_state()

	elif status == OrangeState.roll_stop:
		go_to_walk_state()
		roll_cooldown_timer.start()


func _on_roll_duration_timer_timeout() -> void:
	go_to_roll_stop_state()


func _on_roll_cooldown_timer_timeout() -> void:
	can_roll = true


func _on_death_timer_timeout() -> void:
	queue_free()
