extends Control

var transitioning : bool = false
@onready var fog := $ColorRect/SubViewport/ColorRect

@onready var mainNode := $Main
@onready var textNode := $Text
@onready var instructionsText := $Text/Instructions
@onready var creditsText := $Text/Credits
var home : bool = true

func _process(_delta: float) -> void:
	if transitioning and fog.state == fog.FogState.CONST:
			get_tree().change_scene_to_file("res://main_scene.tscn")

func _on_play_pressed() -> void:
	transitioning = true
	fog.close()

func setup_text():
	home = false
	textNode.visible = true
	mainNode.visible = false
	instructionsText.visible = false
	creditsText.visible = false

func _on_instructions_pressed() -> void:
	setup_text()
	instructionsText.visible = true

func _on_credits_pressed() -> void:
	setup_text()
	creditsText.visible = true

func _on_back_pressed() -> void:
	home = true
	textNode.visible = false
	mainNode.visible = true
