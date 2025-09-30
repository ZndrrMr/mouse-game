extends Area2D

var enabled: bool = false

@onready var fog = $"../CanvasLayer/ColorRect"

func _ready() -> void:
	visible = false

func enable() -> void:
	visible = true
	enabled = true

func _on_body_entered(body: Node2D) -> void:
	if enabled and body.has_method("_get_inputs"):
		# Stop all movement/input
		$"../Snake".set_physics_process(false)
		$"../Player".set_physics_process(false)
		
		var light = preload("res://EndLight.tscn").instantiate()
		get_tree().current_scene.add_child(light)
		light.global_position = global_position
		
		$"../HUD".visible = false
