extends CharacterBody2D

enum SkeletonState {
	walk,
	attack,
	dead
}

const SPINNING_BONE = preload("uid://bql71380nqtcg")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_start_position: Node = $BoneStartPosition
@onready var burst_cooldown_timer: Timer = $BurstCooldownTimer

const JUMP_VELOCITY = -400.0

@export var speed: float = 7.0
@export_range(-1, 1, 2) var initial_direction: int = 1
@export_range(1, 10, 1) var bones_per_burst: int = 3
@export_range(0.1, 30.0, 0.1) var burst_cooldown_seconds: float = 5.0

var status: SkeletonState
var direction: int = 1
var can_throw = true
var bones_thrown_in_burst: int = 0
var burst_is_recharging: bool = false


func _ready() -> void:
	direction = initial_direction
	update_direction()
	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	player_detector.force_raycast_update()
	go_to_walk_state()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		SkeletonState.walk:
			walk_state(delta)

		SkeletonState.dead:
			dead_state(delta)

		SkeletonState.attack:
			attack_state(delta)

	move_and_slide()


func go_to_walk_state():
	status = SkeletonState.walk
	anim.play("walk")


func go_to_attack_state():
	if burst_is_recharging:
		return

	status = SkeletonState.attack
	anim.play("attack")
	velocity = Vector2.ZERO
	can_throw = true


func go_to_dead_state():
	status = SkeletonState.dead
	anim.play("dead")
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO


func walk_state(_delta):
	if anim.frame == 3 or anim.frame == 4:
		velocity.x = speed * direction
	else:
		velocity.x = 0

	if speed > 0.0 and (
		wall_detector.is_colliding()
		or not ground_detector.is_colliding()
	):
		turn_around()

	if player_detector.is_colliding():
		go_to_attack_state()
		return


func attack_state(_delta):
	if anim.frame == 2 and can_throw:
		throw_bone()
		can_throw = false


func dead_state(_delta):
	pass


func turn_around() -> void:
	direction *= -1
	update_direction()


func update_direction() -> void:
	anim.flip_h = direction < 0
	wall_detector.position.x = -2.0 * direction
	wall_detector.target_position.x = 30.0 * direction
	ground_detector.position.x = 13.0 * direction
	player_detector.position.x = 1.0 * direction
	player_detector.target_position.x = 43.0 * direction
	bone_start_position.position.x = 13.0 * direction


func take_damage():
	go_to_dead_state()


func throw_bone():
	var new_bone = SPINNING_BONE.instantiate()

	add_sibling(new_bone)

	new_bone.global_position = bone_start_position.global_position
	new_bone.set_direction(direction)
	bones_thrown_in_burst += 1

	if bones_thrown_in_burst >= bones_per_burst:
		burst_is_recharging = true
		burst_cooldown_timer.start(burst_cooldown_seconds)


func _on_burst_cooldown_timer_timeout() -> void:
	bones_thrown_in_burst = 0
	burst_is_recharging = false


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		go_to_walk_state()
		return
