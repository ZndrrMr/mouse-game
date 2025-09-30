extends Node2D

@onready var fog : ColorRect

var transitioned: bool = false

const FINAL_SIZE := 16.0
const TIME := 3

var t:= 0.0

func stop_all_sounds():
	# Add all your audio players to a group called "audio_players"
	for player in get_tree().get_nodes_in_group("Loops"):
		player.stop()

func _ready() -> void:
	fog = get_tree().get_first_node_in_group("fog")
	stop_all_sounds()
	$AudioStreamPlayer.play()
	$AudioStreamPlayer2.play()
	
func _process(delta: float) -> void:
	if !transitioned:
		if (t <= TIME):
			t += delta
			$PointLight2D.energy = lerp(0.0, FINAL_SIZE, t / TIME)
		else:
			transitioned = true
			$PointLight2D.energy = FINAL_SIZE
			fog.close()
	
	else:
		if fog.state == fog.FogState.CONST:
			get_tree().change_scene_to_file("res://MainMenu.tscn")
