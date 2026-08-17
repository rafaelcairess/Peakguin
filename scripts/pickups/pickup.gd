extends Area2D

## Comportamento compartilhado pelos itens coletáveis.

@export_category("Áudio")
@export var pickup_sound: AudioStream
@export_range(-40.0, 6.0, 0.5) var pickup_volume_db := -6.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var pickup_sfx: AudioStreamPlayer = $PickupSFX

var collected := false


func _ready() -> void:
	pickup_sfx.stream = pickup_sound
	pickup_sfx.volume_db = pickup_volume_db

	# Se este item já foi coletado antes (ex: player morreu e a cena recarregou),
	# remove imediatamente sem aparecer na tela.
	var scene := get_tree().current_scene
	if scene != null:
		var scene_path := scene.scene_file_path
		var item_id := str(get_path())
		if CollectiblesManager.is_collected(scene_path, item_id) \
				or is_persistently_collected(scene_path, item_id):
			queue_free()


func _on_body_entered(body: Node2D) -> void:
	if collected or not collect(body):
		return

	collected = true
	animated_sprite.visible = false
	collision_layer = 0
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)

	# Registra no manager para sobreviver a reloads da cena.
	var scene := get_tree().current_scene
	if scene != null:
		var scene_path := scene.scene_file_path
		var item_id := str(get_path())
		CollectiblesManager.mark_collected(scene_path, item_id)
		register_persistent_collection(scene_path, item_id)

	if pickup_sfx.stream == null:
		queue_free()
		return

	pickup_sfx.play()
	await pickup_sfx.finished
	queue_free()


func collect(_body: Node2D) -> bool:
	return false


func is_persistently_collected(_scene_path: String, _item_id: String) -> bool:
	return false


func register_persistent_collection(_scene_path: String, _item_id: String) -> void:
	pass
