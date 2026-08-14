extends CharacterBody2D

enum CogumeloState {
	idle,
	patrol,
	chase,
	pre_attack,
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
@export_range(16.0, 400.0, 8.0) var chase_distance: float = 240.0
@export_range(16.0, 500.0, 8.0) var forget_distance: float = 400.0
@export_range(1.0, 30.0, 1.0) var forget_time: float = 8.0
var _aggro_time_left: float = 8.0
@export_range(8.0, 320.0, 8.0) var chase_vertical_tolerance: float = 160.0

const WALL_DETECTOR_OFFSET_X: float = 10.0
const WALL_DETECTOR_LENGTH: float = 16.0
const GROUND_DETECTOR_OFFSET_X: float = 18.0
const PLAYER_DETECTOR_OFFSET_X: float = 4.0
const PLAYER_DETECTOR_LENGTH: float = 20.0
const ATTACK_DAMAGE_OFFSET_X: float = 11.0
const ATTACK_DAMAGE_START_FRAME: int = 4
const ATTACK_DAMAGE_END_FRAME: int = 9

const JUMP_VELOCITY: float = -300.0

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
		CogumeloState.idle:
			idle_state()

		CogumeloState.patrol:
			patrol_state()

		CogumeloState.chase:
			chase_state()

		CogumeloState.pre_attack:
			pre_attack_state()

		CogumeloState.attack:
			attack_state()

		CogumeloState.dead:
			dead_state()

	move_and_slide()


func go_to_idle_state() -> void:
	status = CogumeloState.idle
	velocity.x = 0.0
	set_attack_damage_active(false)
	anim.play("idle")


func go_to_patrol_state() -> void:
	status = CogumeloState.patrol
	set_attack_damage_active(false)
	anim.play("run")


func go_to_chase_state() -> void:
	status = CogumeloState.chase
	set_attack_damage_active(false)
	anim.play("run")


func go_to_pre_attack_state() -> void:
	if not can_attack or status == CogumeloState.dead:
		return
		
	status = CogumeloState.pre_attack
	velocity.x = 0.0
	anim.play("idle")
	anim.modulate = Color(1.5, 0.5, 0.5) # Telegrafia visual (vermelho)
	
	await get_tree().create_timer(0.3).timeout
	if status == CogumeloState.pre_attack:
		go_to_attack_state()


func go_to_attack_state() -> void:
	status = CogumeloState.attack
	anim.modulate = Color.WHITE
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

func pre_attack_state() -> void:
	velocity.x = 0.0


func idle_state() -> void:
	if not can_continue_chasing():
		go_to_patrol_state()
		return

	# Vira-se para encarar o player
	var player_direction := signi(roundi(player.global_position.x - global_position.x))
	if player_direction != 0 and player_direction != direction:
		direction = player_direction
		update_direction()
		update_detectors_immediately()

	# Se o caminho ficar livre na direção do player, volta a correr
	if is_on_floor() and not wall_detector.is_colliding() and ground_detector.is_colliding():
		go_to_chase_state()
		return

	try_to_attack_player()


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

	var player_direction := signi(roundi(player.global_position.x - global_position.x))

	if player_direction != 0 and player_direction != direction:
		direction = player_direction
		update_direction()
		update_detectors_immediately()

	var blocked_by_wall = wall_detector.is_colliding()
	var edge_reached = not ground_detector.is_colliding()

	var distance_y = player.global_position.y - global_position.y
	var distance_x = absf(player.global_position.x - global_position.x)
	var player_in_direction = signi(roundi(player.global_position.x - global_position.x)) == direction

	if is_on_floor():
		# Pula se tiver parede, se tiver abismo, ou se estiver bem embaixo do player (floating platforms)
		if blocked_by_wall or edge_reached or (distance_y < -20.0 and distance_x < 30.0):
			
			var can_jump_wall = false
			var can_jump_gap = false
			
			if blocked_by_wall:
				can_jump_wall = _is_wall_jumpable(direction)
			if edge_reached:
				can_jump_gap = _is_gap_jumpable(direction)
				
			# Se a parede for alta demais ou não houver chão do outro lado do buraco,
			# desiste de seguir e volta a patrulhar (padrão Hollow Knight)
			if (blocked_by_wall and not can_jump_wall) or (edge_reached and not can_jump_gap):
				go_to_idle_state()
				return
			
			if distance_y < 16.0 and player_in_direction:
				# Player está acima ou no mesmo nível: PULA
				velocity.y = JUMP_VELOCITY
				velocity.x = chase_speed * direction
			elif edge_reached and distance_y >= 16.0:
				# Player está abaixo e tem abismo: SE JOGA (Desce) se for seguro
				velocity.x = chase_speed * direction
			else:
				go_to_idle_state()
				return
		else:
			velocity.x = chase_speed * direction
	else:
		velocity.x = chase_speed * direction

	try_to_attack_player()


func try_to_attack_player() -> void:
	if (
		can_attack
		and player_detector.is_colliding()
		and player_detector.get_collider() == player
	):
		go_to_pre_attack_state()


func attack_state() -> void:
	velocity.x = 0.0
	set_attack_damage_active(
		anim.frame >= ATTACK_DAMAGE_START_FRAME
		and anim.frame <= ATTACK_DAMAGE_END_FRAME
	)


func dead_state() -> void:
	velocity = Vector2.ZERO

func _is_wall_jumpable(dir: int) -> bool:
	var space_state = get_world_2d().direct_space_state
	var origin = global_position + Vector2(0, -32.0)
	var target = origin + Vector2(WALL_DETECTOR_LENGTH * dir, 0)
	var query = PhysicsRayQueryParameters2D.create(origin, target)
	query.exclude = [self]
	query.collision_mask = wall_detector.collision_mask
	return space_state.intersect_ray(query).is_empty()

func _is_gap_jumpable(dir: int) -> bool:
	var space_state = get_world_2d().direct_space_state
	var origin = global_position + Vector2(40.0 * dir, 10.0)
	var target = origin + Vector2(0, 30.0)
	var query = PhysicsRayQueryParameters2D.create(origin, target)
	query.exclude = [self]
	query.collision_mask = ground_detector.collision_mask
	return not space_state.intersect_ray(query).is_empty()


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
	if absf(distance_to_player.x) <= forget_distance and absf(distance_to_player.y) <= chase_vertical_tolerance:
		_aggro_time_left = forget_time
	else:
		_aggro_time_left -= get_physics_process_delta_time()
		if _aggro_time_left <= 0.0:
			return false

	return true


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
