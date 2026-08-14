extends CharacterBody2D

enum SkeletonState {
	idle,
	walk,
	chase,
	pre_attack,
	attack,
	dead
}

## Monitoramento: patrulha e ataca ao detectar o player via RayCast.
## Torreta: fica parado, mira e atira no player dentro do alcance.
enum SkeletonMode {
	monitoring,
	turret
}

const SPINNING_BONE = preload("uid://bql71380nqtcg")

const WALL_DETECTOR_OFFSET_X: float = -2.0
const WALL_DETECTOR_LENGTH: float = 30.0
const GROUND_DETECTOR_OFFSET_X: float = 13.0
const PLAYER_DETECTOR_OFFSET_X: float = 1.0
const BONE_START_OFFSET_X: float = 13.0
const JUMP_VELOCITY: float = -300.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_start_position: Node2D = $BoneStartPosition
@onready var burst_cooldown_timer: Timer = $BurstCooldownTimer

@export var mode: SkeletonMode = SkeletonMode.monitoring
@export var speed: float = 7.0
@export var chase_speed: float = 40.0
@export_range(-1, 1, 2) var initial_direction: int = 1
@export var player_detection_distance: float = 70.0
@export_range(1, 10, 1) var bones_per_burst: int = 3
@export_range(0.1, 30.0, 0.1) var burst_cooldown_seconds: float = 5.0
@export_range(16.0, 500.0, 8.0) var forget_distance: float = 400.0
@export_range(1.0, 30.0, 1.0) var forget_time: float = 8.0
var _aggro_time_left: float = 8.0

var status: SkeletonState
var direction: int = 1
var can_throw: bool = true
var bones_thrown_in_burst: int = 0
var burst_is_recharging: bool = false
var player: Node2D


func _ready() -> void:
	direction = initial_direction
	update_direction()

	wall_detector.enabled = mode == SkeletonMode.monitoring
	ground_detector.enabled = mode == SkeletonMode.monitoring
	player_detector.enabled = mode == SkeletonMode.monitoring

	if mode == SkeletonMode.monitoring:
		wall_detector.force_raycast_update()
		ground_detector.force_raycast_update()
		player_detector.force_raycast_update()
	else:
		find_player()

	go_to_walk_state()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		SkeletonState.idle:
			idle_state()

		SkeletonState.walk:
			walk_state()

		SkeletonState.chase:
			chase_state()

		SkeletonState.pre_attack:
			pre_attack_state()

		SkeletonState.attack:
			attack_state()

		SkeletonState.dead:
			dead_state()

	move_and_slide()


func go_to_idle_state() -> void:
	status = SkeletonState.idle
	velocity.x = 0
	anim.play("walk")


func go_to_walk_state() -> void:
	status = SkeletonState.walk
	anim.play("walk")


func go_to_chase_state() -> void:
	status = SkeletonState.chase
	anim.play("walk")


func go_to_pre_attack_state() -> void:
	if burst_is_recharging:
		return
		
	status = SkeletonState.pre_attack
	velocity.x = 0
	# Animação de preparação ou pausa dramática (pode ser "idle" por enquanto)
	anim.play("idle")
	anim.modulate = Color(1.5, 0.5, 0.5) # Fica avermelhado para avisar!

	# Espera 0.4s para telegrafar o ataque.
	await get_tree().create_timer(0.4).timeout
	if status == SkeletonState.pre_attack: # Confirma se não morreu ou mudou de estado no meio tempo
		go_to_attack_state()

func go_to_attack_state() -> void:
	status = SkeletonState.attack
	anim.modulate = Color.WHITE # Volta a cor normal
	anim.play("attack")

	# Para enquanto joga o osso.
	velocity.x = 0

	# Permite jogar um osso nesta animação.
	can_throw = true


func go_to_dead_state() -> void:
	if status == SkeletonState.dead:
		return

	status = SkeletonState.dead
	anim.play("dead")

	# Desliga a Hitbox para não continuar causando
	# interações depois de morrer.
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO


func dead_state() -> void:
	velocity = Vector2.ZERO

func pre_attack_state() -> void:
	# Fica parado enquanto brilha de vermelho antes do ataque
	velocity.x = 0
	
func idle_state() -> void:
	if not is_instance_valid(player):
		find_player()
		
	if player != null and global_position.distance_to(player.global_position) <= player_detection_distance:
		go_to_chase_state()
		return
	
	go_to_walk_state()


func chase_state() -> void:
	if not is_instance_valid(player):
		find_player()
		if player == null:
			go_to_walk_state()
			return

	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player <= forget_distance:
		_aggro_time_left = forget_time
	else:
		_aggro_time_left -= get_physics_process_delta_time()
		if _aggro_time_left <= 0.0:
			go_to_walk_state()
			return

	if not burst_is_recharging and is_on_floor():
		go_to_pre_attack_state()
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
		if blocked_by_wall or edge_reached or (distance_y < -20.0 and distance_x < 30.0):
			
			var can_jump_wall = false
			var can_jump_gap = false
			
			if blocked_by_wall:
				can_jump_wall = _is_wall_jumpable(direction)
			if edge_reached:
				can_jump_gap = _is_gap_jumpable(direction)
				
			# Se a parede for alta demais, ou o buraco largo demais, desiste.
			if (blocked_by_wall and not can_jump_wall) or (edge_reached and not can_jump_gap):
				go_to_idle_state()
				return
			
			if distance_y < 16.0 and player_in_direction:
				velocity.y = JUMP_VELOCITY
				velocity.x = chase_speed * direction
			elif edge_reached and distance_y >= 16.0:
				velocity.x = chase_speed * direction
			else:
				go_to_idle_state()
				return
		else:
			velocity.x = chase_speed * direction
	else:
		velocity.x = chase_speed * direction


func _is_wall_jumpable(dir: int) -> bool:
	# Checa se o topo da parede é livre para pular
	var space_state = get_world_2d().direct_space_state
	var origin = global_position + Vector2(0, -32.0) # Ajuste dependendo da altura máxima de pulo
	var target = origin + Vector2(WALL_DETECTOR_LENGTH * dir, 0)
	var query = PhysicsRayQueryParameters2D.create(origin, target)
	query.exclude = [self]
	query.collision_mask = wall_detector.collision_mask
	return space_state.intersect_ray(query).is_empty()

func _is_gap_jumpable(dir: int) -> bool:
	# Checa se existe chão do outro lado do buraco (a uns 40 pixels pra frente)
	var space_state = get_world_2d().direct_space_state
	var origin = global_position + Vector2(40.0 * dir, 10.0)
	var target = origin + Vector2(0, 30.0)
	var query = PhysicsRayQueryParameters2D.create(origin, target)
	query.exclude = [self]
	query.collision_mask = ground_detector.collision_mask
	return not space_state.intersect_ray(query).is_empty()


func walk_state() -> void:
	match mode:
		SkeletonMode.monitoring:
			patrol()
			check_for_player()

		SkeletonMode.turret:
			velocity.x = 0
			turret_aim()


func patrol() -> void:
	# Seu sprite só anda visualmente em determinados frames.
	if anim.frame == 3 or anim.frame == 4:
		velocity.x = speed * direction
	else:
		velocity.x = 0

	# Encontrou parede ou acabou o chão: vira para o outro lado.
	if (
		wall_detector.is_colliding()
		or not ground_detector.is_colliding()
	):
		turn_around()


func check_for_player() -> void:
	if player_detector.is_colliding():
		go_to_chase_state()


func turret_aim() -> void:
	if not is_instance_valid(player):
		find_player()
		return

	var distance := global_position.distance_to(player.global_position)

	if distance > player_detection_distance:
		return

	# Vira para o lado onde o player está.
	var player_direction := signi(roundi(player.global_position.x - global_position.x))
	if player_direction != 0 and player_direction != direction:
		direction = player_direction
		update_direction()

	go_to_pre_attack_state()


func attack_state() -> void:
	# O osso é lançado no frame 2 da animação.
	if anim.frame == 2 and can_throw:
		throw_bone()
		# Impede que o mesmo frame crie vários ossos.
		can_throw = false




func turn_around() -> void:
	direction *= -1
	update_direction()
	update_detectors_immediately()


func find_player() -> void:
	player = get_tree().get_first_node_in_group("Player") as Node2D


func update_direction() -> void:
	# direction:
	#  1 = direita
	# -1 = esquerda

	anim.flip_h = direction < 0

	# RayCast de parede.
	wall_detector.position.x = WALL_DETECTOR_OFFSET_X * direction
	wall_detector.target_position.x = WALL_DETECTOR_LENGTH * direction

	# RayCast que procura chão à frente.
	ground_detector.position.x = GROUND_DETECTOR_OFFSET_X * direction

	# Campo de visão do Skeleton (modo monitoramento).
	player_detector.position.x = PLAYER_DETECTOR_OFFSET_X * direction
	player_detector.target_position.x = player_detection_distance * direction

	# Ponto de onde nasce o osso.
	bone_start_position.position.x = BONE_START_OFFSET_X * direction


func update_detectors_immediately() -> void:
	wall_detector.force_raycast_update()
	ground_detector.force_raycast_update()
	player_detector.force_raycast_update()


func take_damage() -> void:
	go_to_dead_state()


func throw_bone() -> void:
	var new_bone = SPINNING_BONE.instantiate()

	add_sibling(new_bone)

	new_bone.global_position = bone_start_position.global_position

	# Faz o osso viajar para o lado correto.
	new_bone.set_direction(direction)

	bones_thrown_in_burst += 1

	# Depois do último osso do burst: entra em cooldown.
	if bones_thrown_in_burst >= bones_per_burst:
		burst_is_recharging = true
		burst_cooldown_timer.start(burst_cooldown_seconds)


func _on_burst_cooldown_timer_timeout() -> void:
	# Terminou o cooldown.
	# Pode começar outro conjunto de ossos.
	bones_thrown_in_burst = 0
	burst_is_recharging = false


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		if mode == SkeletonMode.monitoring:
			go_to_chase_state()
		else:
			go_to_walk_state()
		return
