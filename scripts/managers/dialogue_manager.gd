extends Node

signal dialogue_started
signal dialogue_ended

var dialogue_box_scene: PackedScene = preload("res://ui/dialogue/dialogue_box.tscn")
var current_dialogue_box: Node = null

func start_dialogue(lines: Array[String], speaker_name: String = "", portrait: Texture2D = null) -> void:
	if current_dialogue_box != null:
		return
	
	var ui_layer = get_tree().get_first_node_in_group("UI_Layer")
	if ui_layer == null:
		# Fallback se não tivermos um CanvasLayer de UI explícito
		ui_layer = get_tree().current_scene

	current_dialogue_box = dialogue_box_scene.instantiate()
	ui_layer.add_child(current_dialogue_box)
	
	dialogue_started.emit()
	
	current_dialogue_box.start(lines, speaker_name, portrait)
	current_dialogue_box.finished.connect(_on_dialogue_finished)

func _on_dialogue_finished() -> void:
	if current_dialogue_box != null:
		current_dialogue_box.queue_free()
		current_dialogue_box = null
		
	dialogue_ended.emit()
	
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		var player = players[0]
		# Volta para natação se estiver na água, caso contrário idle
		if player.water_bodies.size() > 0:
			player.go_to_swimming_state()
		else:
			player.go_to_idle_state()
