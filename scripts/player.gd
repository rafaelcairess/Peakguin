extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	victory,
	slide,
	dead
}

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D

@export var max_speed: float = 180.0
@export var acceleration: float = 400.0
@export var deceleration: float = 400.0
@export var slide_deceleration: float = 100.0
@export var max_jump_count: int = 2

const JUMP_VELOCITY: float = -300.0

var direction: float = 0.0
var status: PlayerState
var jump_count: int = 0


func _ready() -> void:
	set_large_collider()
	go_to_idle_state()


func _physics_process(delta: float) -> void:
	if status != PlayerState.dead:
		if not is_on_floor():
			velocity += get_gravity() * delta

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

		PlayerState.victory:
			victory_state(delta)

		PlayerState.slide:
			slide_state(delta)

		PlayerState.dead:
			dead_state(delta)


func go_to_idle_state():
	status = PlayerState.idle
	anim.play("idle")


func go_to_walk_state():
	status = PlayerState.walk
	anim.play("walk")


func go_to_jump_state():
	status = PlayerState.jump
	anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1


func go_to_fall_state():
	status = PlayerState.fall
	anim.play("fall")


func go_to_duck_state():
	status = PlayerState.duck
	anim.play("duck")
	set_small_collider()


func exit_from_duck_state():
	set_large_collider()


func go_to_slide_state():
	status = PlayerState.slide
	anim.play("slide")
	set_small_collider()


func exit_from_slide_state():
	set_large_collider()


func go_to_victory_state():
	status = PlayerState.victory
	anim.play("victorydance")
	velocity.x = 0


func exit_from_victory_state():
	go_to_idle_state()


func go_to_dead_state():
	status = PlayerState.dead
	velocity = Vector2.ZERO
	anim.play("dead")


func idle_state(delta):
	move(delta)

	if velocity.x != 0:
		go_to_walk_state()
		return

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return

	if Input.is_action_just_pressed("victory"):
		go_to_victory_state()
		return


func walk_state(delta):
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

	if Input.is_action_just_pressed("victory"):
		go_to_victory_state()
		return


func jump_state(delta):
	move(delta)

	if Input.is_action_just_pressed("jump") and can_jump():
		go_to_jump_state()
		return

	if velocity.y > 0:
		go_to_fall_state()
		return


func fall_state(delta):
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


func duck_state(_delta):
	update_direction()
	velocity.x = 0
	move_and_slide()

	if Input.is_action_just_released("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return


func victory_state(_delta):
	velocity.x = 0
	move_and_slide()

	if Input.is_action_just_pressed("victory"):
		exit_from_victory_state()
		return


func slide_state(delta):
	velocity.x = move_toward(
		velocity.x,
		0,
		slide_deceleration * delta
	)

	move_and_slide()

	if Input.is_action_just_released("duck"):
		exit_from_slide_state()

		if velocity.x != 0:
			go_to_walk_state()
		else:
			go_to_idle_state()

		return

	if velocity.x == 0:
		go_to_duck_state()
		return


func dead_state(_delta):
	velocity = Vector2.ZERO


func move(delta):
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

	move_and_slide()


func update_direction():
	direction = Input.get_axis("left", "right")

	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false


func can_jump() -> bool:
	return jump_count < max_jump_count


func set_small_collider():
	var capsule := collision_shape.shape as CapsuleShape2D

	if capsule != null:
		capsule.radius = 4.0
		capsule.height = 8.0
		collision_shape.position.y = 4.0

	var hitbox_rect := hitbox_shape.shape as RectangleShape2D

	if hitbox_rect != null:
		hitbox_rect.size = Vector2(12, 5)
		hitbox_shape.position.y = 5.5


func set_large_collider():
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

	if velocity.y > 0:
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		go_to_dead_state()


func _on_reload_timer_timeout() -> void:
	pass
