extends AnimatedSprite2D

var t : float = 0.0
var start: bool = false
var transitioning: bool = false

@onready var fog : ColorRect

func _ready() -> void:
	$AudioStreamPlayer.play()
	fog = get_tree().get_first_node_in_group("fog")
	
func _process(delta: float) -> void:
	global_position = $"../Camera2D".global_position
	
	t+= delta
	
	if (t < 3):
		global_position.x += randf_range(-16, 16)
	elif !start:
		start = true
		play("default")
	
	if transitioning and fog.state == fog.FogState.CONST:
		get_tree().change_scene_to_file("res://MainMenu.tscn")


func _on_animation_finished() -> void:
	transitioning = true
	fog.close()
