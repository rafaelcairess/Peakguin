extends CharacterBody2D

enum CogumeloState {
	patrol,
	chase,
	attack,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var attack_damage: Area2D = $AttackDamage
@onready var attack_damage_shape: CollisionShape2D = $AttackDamage/CollisionShape2D
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var attack_cooldown_timer: Timer = $AttackCooldownTimer

@export var speed: float = 25.0
@export_range(-1, 1, 2) var initial_direction: int = 1
@export_range(0.1, 10.0, 0.1) var attack_cooldown_seconds: float = 1.0

@export_category("Perseguição")
@export var chase_speed: float = 45.0
@export_range(16.0, 320.0, 8.0) var chase_distance: float = 160.0
@export_range(16.0, 400.0, 8.0) var forget_distance: float = 208.0
@export_range(8.0, 128.0, 8.0) var chase_vertical_tolerance: float = 48.0

const WALL_DETECTOR_OFFSET_X: float = 10.0
const WALL_DETECTOR_LENGTH: float = 16.0
const GROUND_DETECTOR_OFFSET_X: float = 18.0
const PLAYER_DETECTOR_OFFSET_X: float = 4.0
const PLAYER_DETECTOR_LENGTH: float = 20.0
const ATTACK_DAMAGE_OFFSET_X: float = 11.0
const ATTACK_DAMAGE_START_FRAME: int = 4
const ATTACK_DAMAGE_END_FRAME: int = 9

var status: CogumeloState = CogumeloState.patrol
var direction: int = 1
var can_attack: bool = true
var player: Node2D


func _ready() -> void:
	direction = initial_direction
	find_player()
	attack_cooldown_timer.wait_time = attack_cooldown_seconds
	attack_damage_shape.disabled = true
	update_direction()
	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	player_detector.force_raycast_update()
	go_to_patrol_state()


func _physics_process(delta: float) -> void:
	if status != CogumeloState.dead and not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		CogumeloState.patrol:
			patrol_state()

		CogumeloState.chase:
			chase_state()

		CogumeloState.attack:
			attack_state()

		CogumeloState.dead:
			dead_state()

	move_and_slide()


func go_to_patrol_state() -> void:
	status = CogumeloState.patrol
	set_attack_damage_active(false)
	anim.play("run")


func go_to_chase_state() -> void:
	status = CogumeloState.chase
	set_attack_damage_active(false)
	anim.play("run")


func go_to_attack_state() -> void:
	if not can_attack or status == CogumeloState.dead:
		return

	status = CogumeloState.attack
	velocity.x = 0.0
	can_attack = false
	set_attack_damage_active(false)
	anim.play("attack")


func go_to_dead_state() -> void:
	if status == CogumeloState.dead:
		return

	status = CogumeloState.dead
	velocity = Vector2.ZERO
	anim.play("dead")
	set_attack_damage_active(false)
	collision_shape.set_deferred("disabled", true)
	hitbox_shape.set_deferred("disabled", true)


func patrol_state() -> void:
	if can_start_chasing():
		go_to_chase_state()
		return

	velocity.x = speed * direction

	if is_on_floor() and (
		wall_detector.is_colliding()
		or not ground_detector.is_colliding()
	):
		turn_around()
		return

	try_to_attack_player()


func chase_state() -> void:
	if not can_continue_chasing():
		go_to_patrol_state()
		return

	var player_direction := signi(player.global_position.x - global_position.x)

	if player_direction != 0 and player_direction != direction:
		direction = player_direction
		update_direction()
		update_detectors_immediately()

	# O cogumelo não se joga de plataformas para alcançar o player.
	# Se houver parede ou precipício, ele espera na borda enquanto mantém o alvo.
	if is_on_floor() and (
		wall_detector.is_colliding()
		or not ground_detector.is_colliding()
	):
		velocity.x = 0.0
	else:
		velocity.x = chase_speed * direction

	try_to_attack_player()


func try_to_attack_player() -> void:
	if (
		can_attack
		and player_detector.is_colliding()
		and player_detector.get_collider() == player
	):
		go_to_attack_state()


func attack_state() -> void:
	velocity.x = 0.0
	set_attack_damage_active(
		anim.frame >= ATTACK_DAMAGE_START_FRAME
		and anim.frame <= ATTACK_DAMAGE_END_FRAME
	)


func dead_state() -> void:
	velocity = Vector2.ZERO


func turn_around() -> void:
	direction *= -1
	velocity.x = 0.0
	update_direction()
	update_detectors_immediately()


func find_player() -> void:
	player = get_tree().get_first_node_in_group("Player") as Node2D


func can_start_chasing() -> bool:
	if not is_instance_valid(player):
		find_player()

	if player == null:
		return false

	var distance_to_player := player.global_position - global_position
	return (
		absf(distance_to_player.x) <= chase_distance
		and absf(distance_to_player.y) <= chase_vertical_tolerance
	)


func can_continue_chasing() -> bool:
	if not is_instance_valid(player):
		find_player()

	if player == null:
		return false

	var distance_to_player := player.global_position - global_position
	return (
		absf(distance_to_player.x) <= forget_distance
		and absf(distance_to_player.y) <= chase_vertical_tolerance
	)


func update_direction() -> void:
	# Os frames originais do cogumelo olham para a esquerda.
	anim.flip_h = direction > 0
	wall_detector.position.x = WALL_DETECTOR_OFFSET_X * direction
	wall_detector.target_position.x = WALL_DETECTOR_LENGTH * direction
	ground_detector.position.x = GROUND_DETECTOR_OFFSET_X * direction
	player_detector.position.x = PLAYER_DETECTOR_OFFSET_X * direction
	player_detector.target_position.x = PLAYER_DETECTOR_LENGTH * direction
	attack_damage.position.x = ATTACK_DAMAGE_OFFSET_X * direction


func update_detectors_immediately() -> void:
	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	player_detector.force_raycast_update()


func set_attack_damage_active(active: bool) -> void:
	attack_damage_shape.set_deferred("disabled", not active)


func take_damage() -> void:
	go_to_dead_state()


func _on_animated_sprite_2d_animation_finished() -> void:
	if status == CogumeloState.attack:
		attack_cooldown_timer.start()

		if can_continue_chasing():
			go_to_chase_state()
		else:
			go_to_patrol_state()

	elif status == CogumeloState.dead:
		queue_free()


func _on_attack_cooldown_timer_timeout() -> void:
	can_attack = true
