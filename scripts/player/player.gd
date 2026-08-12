extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	swimming,
	sit,
	victory,
	slide,
	wall,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var left_wall_detector: RayCast2D = $LeftWallDetector
@onready var right_wall_detector: RayCast2D = $RightWallDetector
@onready var reload_timer: Timer = $ReloadTimer
@onready var jump_sfx: AudioStreamPlayer = $JumpSFX
@onready var footstep_sfx: AudioStreamPlayer = $FootstepSFX
@onready var water_sfx: AudioStreamPlayer = $WaterSFX
@onready var lava_sfx: AudioStreamPlayer = $LavaSFX

@export var max_speed: float = 180.0
@export var acceleration: float = 400.0
@export var deceleration: float = 400.0
@export var slide_deceleration: float = 100.0
@export var max_jump_count: int = 2
@export var idle_to_sit_time: float = 25.0

@export var wall_aceleration: float = 40.0
@export var wall_jump_velocity: float = 240.0

@export var water_max_speed: float = 100.0
@export var water_acceleration: float = 200.0
@export var water_jump_force: float = -100.0

@export_category("Audio")
@export var grass_footstep_sounds: Array[AudioStream] = [
	preload("res://audio/sfx/environment/grass/grass_step_01.wav"),
	preload("res://audio/sfx/environment/grass/grass_step_02.wav"),
	preload("res://audio/sfx/environment/grass/grass_step_03.wav")
]
@export_range(0.1, 1.0, 0.01) var grass_footstep_interval: float = 0.28
@export var water_splash_scene: PackedScene = preload("res://effects/water_splash/water_splash.tscn")

const JUMP_VELOCITY: float = -300.0

var direction: float = 0.0
var status: PlayerState
var jump_count: int = 0
var idle_time: float = 0.0
var grass_footstep_elapsed: float = 0.0
var water_bodies: Array[Node2D] = []


func _ready() -> void:
	var current_scene := get_tree().current_scene

	if current_scene != null:
		global_position = CheckpointManager.get_respawn_position(
			current_scene.scene_file_path,
			global_position
		)

	set_large_collider()
	go_to_idle_state()


func _physics_process(delta: float) -> void:
	match status:
		PlayerState.idle:
			idle_state(delta)

		PlayerState.walk:
			walk_state(delta)

		PlayerState.jump:
			jump_state(delta)

		PlayerState.fall:
			fall_state(delta)

		PlayerState.duck:
			duck_state(delta)

		PlayerState.swimming:
			swimming_state(delta)

		PlayerState.sit:
			sit_state(delta)

		PlayerState.victory:
			victory_state(delta)

		PlayerState.slide:
			slide_state(delta)

		PlayerState.wall:
			wall_state(delta)

		PlayerState.dead:
			dead_state(delta)

	move_and_slide()


func go_to_idle_state() -> void:
	status = PlayerState.idle
	anim.play("idle")
	idle_time = 0.0


func go_to_walk_state() -> void:
	status = PlayerState.walk
	anim.play("walk")
	grass_footstep_elapsed = grass_footstep_interval


func go_to_jump_state() -> void:
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1
	play_jump_sfx()


func go_to_fall_state() -> void:
	status = PlayerState.fall
	anim.play("fall")


func go_to_duck_state() -> void:
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()


func exit_from_duck_state() -> void:
	set_large_collider()


func go_to_slide_state() -> void:
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()


func exit_from_slide_state() -> void:
	set_large_collider()


func go_to_wall_state() -> void:
	status = PlayerState.wall
	anim.play("wall")
	velocity = Vector2.ZERO
	jump_count = 0


func go_to_swimming_state() -> void:
	status = PlayerState.swimming
	anim.play("swimming")

	# Evita entrar na água caindo rápido demais
	velocity.y = min(
		velocity.y,
		water_max_speed
	)


func go_to_sit_state() -> void:
	status = PlayerState.sit
	anim.play("sit")
	velocity.x = 0
	idle_time = 0.0


func exit_from_sit_state() -> void:
	go_to_idle_state()


func go_to_victory_state() -> void:
	status = PlayerState.victory
	anim.play("victorydance")
	velocity.x = 0


func exit_from_victory_state() -> void:
	go_to_idle_state()


func go_to_dead_state() -> void:
	if status == PlayerState.dead:
		return

	status = PlayerState.dead
	velocity = Vector2.ZERO
	anim.play("dead")
	grass_footstep_elapsed = 0.0
	reload_timer.start()


func idle_state(delta: float) -> void:
	apply_gravity(delta)
	move(delta)

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return

	if velocity.x != 0:
		go_to_walk_state()
		return

	if Input.is_action_just_pressed("sit"):
		go_to_sit_state()
		return

	if Input.is_action_just_pressed("victory"):
		go_to_victory_state()
		return

	idle_time += delta

	if idle_time >= idle_to_sit_time:
		go_to_sit_state()
		return


func walk_state(delta: float) -> void:
	apply_gravity(delta)
	move(delta)

	if velocity.x == 0:
		go_to_idle_state()
		return

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return

	if not is_on_floor():
		go_to_fall_state()
		return

	if Input.is_action_just_pressed("sit"):
		go_to_sit_state()
		return

	if Input.is_action_just_pressed("victory"):
		go_to_victory_state()
		return

	update_grass_footsteps(delta)


func jump_state(delta: float) -> void:
	apply_gravity(delta)
	move(delta)

	if Input.is_action_just_pressed("jump") and can_jump():
		go_to_jump_state()
		return

	if velocity.y > 0:
		go_to_fall_state()
		return


func fall_state(delta: float) -> void:
	apply_gravity(delta)
	move(delta)

	if Input.is_action_just_pressed("jump") and can_jump():
		go_to_jump_state()
		return

	if is_on_floor():
		jump_count = 0

		if velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()

		return

	if (
		left_wall_detector.is_colliding()
		or right_wall_detector.is_colliding()
	) and is_on_wall():
		go_to_wall_state()
		return


func duck_state(delta: float) -> void:
	apply_gravity(delta)
	update_direction()

	velocity.x = 0

	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return


func victory_state(delta: float) -> void:
	apply_gravity(delta)

	velocity.x = 0

	if Input.is_action_just_pressed("victory"):
		exit_from_victory_state()
		return


func sit_state(delta: float) -> void:
	apply_gravity(delta)
	update_direction()

	velocity.x = 0

	if direction != 0:
		go_to_walk_state()
		return

	if Input.is_action_just_pressed("sit"):
		exit_from_sit_state()
		return


func slide_state(delta: float) -> void:
	apply_gravity(delta)

	velocity.x = move_toward(
		velocity.x,
		0,
		slide_deceleration * delta
	)

	if Input.is_action_just_released("duck"):
		exit_from_slide_state()

		if velocity.x != 0:
			go_to_walk_state()
		else:
			go_to_idle_state()

		return

	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return


func wall_state(delta: float) -> void:
	velocity.y += wall_aceleration * delta

	if left_wall_detector.is_colliding():
		anim.flip_h = false
		direction = 1

	elif right_wall_detector.is_colliding():
		anim.flip_h = true
		direction = -1

	else:
		go_to_fall_state()
		return

	if is_on_floor():
		go_to_idle_state()
		return

	if Input.is_action_just_pressed("jump"):
		velocity.x = wall_jump_velocity * direction
		go_to_jump_state()
		return


func swimming_state(delta: float) -> void:
	update_direction()

	# Movimento horizontal dentro da água
	if direction:
		velocity.x = move_toward(
			velocity.x,
			water_max_speed * direction,
			water_acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			water_acceleration * delta
		)

	# Gravidade suave dentro da água
	velocity.y += water_acceleration * delta

	# Limita a velocidade de queda
	velocity.y = min(
		velocity.y,
		water_max_speed
	)

	# Cada toque no jump dá uma "nadada" para cima
	if Input.is_action_just_pressed("jump"):
		velocity.y = water_jump_force
		play_water_sfx(false)


func dead_state(_delta: float) -> void:
	velocity = Vector2.ZERO


func move(delta: float) -> void:
	update_direction()

	if direction:
		velocity.x = move_toward(
			velocity.x,
			direction * max_speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			deceleration * delta
		)


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta


func update_direction() -> void:
	direction = Input.get_axis("left", "right")

	if direction < 0:
		anim.flip_h = true

	elif direction > 0:
		anim.flip_h = false


func can_jump() -> bool:
	return jump_count < max_jump_count


func update_grass_footsteps(delta: float) -> void:
	if not is_on_grass_surface() or grass_footstep_sounds.is_empty():
		grass_footstep_elapsed = grass_footstep_interval
		return

	grass_footstep_elapsed += delta

	if grass_footstep_elapsed < grass_footstep_interval:
		return

	grass_footstep_elapsed = 0.0
	footstep_sfx.stream = grass_footstep_sounds.pick_random()
	footstep_sfx.pitch_scale = randf_range(0.92, 1.08)
	footstep_sfx.play()


func is_on_grass_surface() -> bool:
	if not is_on_floor():
		return false

	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)

		if collision.get_normal().dot(up_direction) < 0.7:
			continue

		var collider := collision.get_collider()

		if collider is Node and collider.is_in_group("GrassSurface"):
			return true

	return false


func play_jump_sfx() -> void:
	jump_sfx.pitch_scale = randf_range(0.97, 1.03)
	jump_sfx.play()


func play_water_sfx(is_large_splash: bool) -> void:
	if is_large_splash:
		water_sfx.volume_db = -3.0
		water_sfx.pitch_scale = randf_range(0.9, 1.05)
	else:
		water_sfx.volume_db = -9.0
		water_sfx.pitch_scale = randf_range(1.12, 1.28)

	water_sfx.play()


func spawn_water_splash(water_body: Node2D) -> void:
	if water_splash_scene == null:
		return

	var splash := water_splash_scene.instantiate() as Node2D

	if splash == null:
		return

	var scene_root := get_tree().current_scene
	var splash_parent: Node = scene_root if scene_root != null else get_parent()
	splash_parent.add_child(splash)
	splash.global_position = Vector2(
		global_position.x,
		find_water_surface_y(water_body)
	)


func find_water_surface_y(water_body: Node2D) -> float:
	if water_body is TileMapLayer:
		var water_layer := water_body as TileMapLayer
		var local_player_position := water_layer.to_local(global_position)
		var player_cell := water_layer.local_to_map(local_player_position)
		var surface_cell := player_cell
		var found_water_cell := false

		for vertical_offset in range(-4, 5):
			var candidate := Vector2i(player_cell.x, player_cell.y + vertical_offset)

			if water_layer.get_cell_source_id(candidate) != -1:
				surface_cell = candidate
				found_water_cell = true
				break

		if found_water_cell:
			while water_layer.get_cell_source_id(surface_cell + Vector2i.UP) != -1:
				surface_cell += Vector2i.UP

			var cell_center := water_layer.map_to_local(surface_cell)
			var cell_size := Vector2(water_layer.tile_set.tile_size)
			var surface_local := cell_center - Vector2(0.0, cell_size.y * 0.5)
			return water_layer.to_global(surface_local).y

	return global_position.y


func set_small_collider() -> void:
	var capsule := collision_shape.shape as CapsuleShape2D

	if capsule != null:
		capsule.radius = 4.0
		capsule.height = 8.0
		collision_shape.position.y = 4.0

	var hitbox_rect := hitbox_shape.shape as RectangleShape2D

	if hitbox_rect != null:
		hitbox_rect.size = Vector2(12, 5)
		hitbox_shape.position.y = 5.5


func set_large_collider() -> void:
	var capsule := collision_shape.shape as CapsuleShape2D

	if capsule != null:
		capsule.radius = 6.0
		capsule.height = 16.0
		collision_shape.position.y = 0.0

	var hitbox_rect := hitbox_shape.shape as RectangleShape2D

	if hitbox_rect != null:
		hitbox_rect.size = Vector2(14, 16)
		hitbox_shape.position.y = 0.0


func _on_hitbox_area_entered(area: Area2D) -> void:
	if status == PlayerState.dead:
		return

	if area.is_in_group("Enemies"):
		hit_enemy(area)

	elif area.is_in_group("LethalArea"):
		hit_lethal_area(area)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		hit_lethal_area(body)

	elif body.is_in_group("Water"):
		if body not in water_bodies:
			water_bodies.append(body)

		if water_bodies.size() == 1:
			play_water_sfx(true)
			spawn_water_splash(body)
			go_to_swimming_state()


func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Water"):
		water_bodies.erase(body)

		if water_bodies.is_empty():
			play_water_sfx(true)
			spawn_water_splash(body)
			jump_count = 0
			go_to_jump_state()


func hit_enemy(area: Area2D) -> void:
	if velocity.y > 0:
		area.get_parent().take_damage()
		go_to_jump_state()

	else:
		go_to_dead_state()


func hit_lethal_area(source: Node) -> void:
	if source.is_in_group("Lava"):
		lava_sfx.play()

	go_to_dead_state()


func _on_reload_timer_timeout() -> void:
	get_tree().reload_current_scene()
