extends Node

## Configura os cursores pixel art e aplica a mão aos botões da interface.

const MOUSE_ICONS: Texture2D = preload(
	"res://sprites/Mini FX, Items & UI/Mini UI/Mouse_Icons_Outlined_Drop-shadowed (16 x 16).png"
)


func _ready() -> void:
	Input.set_custom_mouse_cursor(
		_make_cursor(Rect2(0, 0, 16, 16)),
		Input.CURSOR_ARROW,
		Vector2.ZERO
	)
	Input.set_custom_mouse_cursor(
		_make_cursor(Rect2(16, 0, 16, 16)),
		Input.CURSOR_POINTING_HAND,
		Vector2(6, 1)
	)

	get_tree().node_added.connect(_on_node_added)
	call_deferred("_apply_cursor_to_branch", get_tree().root)


func _exit_tree() -> void:
	Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)
	Input.set_custom_mouse_cursor(null, Input.CURSOR_POINTING_HAND)


func _make_cursor(region: Rect2) -> AtlasTexture:
	var cursor := AtlasTexture.new()
	cursor.atlas = MOUSE_ICONS
	cursor.region = region
	return cursor


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _apply_cursor_to_branch(node: Node) -> void:
	_on_node_added(node)
	for child in node.get_children():
		_apply_cursor_to_branch(child)
