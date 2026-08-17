extends CanvasLayer
## HUD reutilizável que acompanha o Player em todas as fases.
## Independente do ciclo de vida do Player: não é mais filho dele,
## e o cronômetro vive no autoload RunTimer, então sobrevive
## a troca de cena e a morte do player.

@export var numbers_texture: Texture2D = preload(
	"res://sprites/Mini FX, Items & UI/Mini UI/Timer_Coin_Numbers_Drop-shadowed (8 x 8).png"
)
@export var health_texture: Texture2D = preload(
	"res://sprites/Mini FX, Items & UI/Mini UI/Health_Indicator_Black_Outline (8 x 8).png"
)

@onready var health_row: HBoxContainer = %HealthRow
@onready var time_digits: HBoxContainer = %TimeDigits
@onready var coin_digits: HBoxContainer = %CoinDigits

var player: Node
var digit_cache: Array[AtlasTexture] = []
var full_heart: AtlasTexture
var empty_heart: AtlasTexture


func _ready() -> void:
	_build_texture_cache()

	RunTimer.second_changed.connect(_update_timer)
	_update_timer(RunTimer.get_current_second())

	_set_number(coin_digits, 0)
	_on_health_changed(3, 3)

	_find_and_bind_player()

	# Caso o player seja recriado (respawn/reload de cena), reconecta.
	get_tree().node_added.connect(_on_node_added)


func _on_node_added(node: Node) -> void:
	if player != null and is_instance_valid(player):
		return
	if node.is_in_group("Player"):
		_find_and_bind_player()


func _find_and_bind_player() -> void:
	var candidates := get_tree().get_nodes_in_group("Player")
	if candidates.is_empty():
		return

	player = candidates[0]

	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
	if player.has_signal("coins_changed"):
		player.coins_changed.connect(_on_coins_changed)

	_on_health_changed(
		int(player.get("current_health")),
		int(player.get("max_health"))
	)
	_on_coins_changed(int(player.get("coins")))


func _update_timer(total_seconds: int) -> void:
	var minutes := mini(total_seconds / 60, 99)
	var seconds := total_seconds % 60
	var text := "%02d%02d" % [minutes, seconds]
	var digit_index := 0
	for node in time_digits.get_children():
		var digit_node := node as TextureRect
		if digit_node == null:
			continue
		digit_node.texture = digit_cache[text.substr(digit_index, 1).to_int()]
		digit_index += 1


func _build_texture_cache() -> void:
	digit_cache.clear()
	for digit in range(10):
		var column := digit + 1 if digit < 5 else digit - 4
		var row := 0 if digit < 5 else 1
		digit_cache.append(_make_atlas(numbers_texture, Rect2(column * 8, row * 8, 8, 8)))
	full_heart = _make_atlas(health_texture, Rect2(0, 0, 8, 8))
	empty_heart = _make_atlas(health_texture, Rect2(8, 0, 8, 8))


func _make_atlas(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas


func _set_number(container: HBoxContainer, value: int) -> void:
	if digit_cache.size() != 10:
		return
	var digit_nodes := container.get_children()
	var digits_count := digit_nodes.size()
	var maximum := int(pow(10, digits_count)) - 1
	var text := str(clampi(value, 0, maximum)).pad_zeros(digits_count)
	for index in range(digits_count):
		var digit_node := digit_nodes[index] as TextureRect
		if digit_node != null:
			digit_node.texture = digit_cache[text.substr(index, 1).to_int()]


func _on_health_changed(current_health: int, maximum_health: int) -> void:
	var hearts := health_row.get_children()
	for index in range(hearts.size()):
		var heart := hearts[index] as TextureRect
		if heart == null:
			continue
		heart.visible = index < maximum_health
		heart.texture = full_heart if index < current_health else empty_heart


func _on_coins_changed(total: int) -> void:
	_set_number(coin_digits, total)
