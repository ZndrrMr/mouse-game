extends Control

var transitioning : bool = false
@onready var fog := $ColorRect

func _process(delta: float) -> void:
	if transitioning and fog.state == fog.FogState.CONST:
			get_tree().change_scene_to_file("res://main_scene.tscn")

func _on_play_pressed() -> void:
	transitioning = true
	fog.close()
