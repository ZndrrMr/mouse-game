extends Node2D

var host: CharacterBody2D

func _physics_process(delta: float) -> void:
	$AudioStreamPlayer2D.stream_paused = host.velocity.length() <= 0

func _setup(snake: CharacterBody2D) -> void:
	host = snake
	$AudioStreamPlayer2D.play()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("_get_inputs") and !body.is_hidden() and host.state == host.state_map[host.SnakeStates.PATROL]:
		host.change_state(host.SnakeStates.CHASE)
		host.set_patrol_target()
		$AudioStreamPlayer.play()
